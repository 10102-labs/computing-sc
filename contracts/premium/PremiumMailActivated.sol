// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/NotifyLib.sol";
import "../libraries/FormatUnits.sol";
import "../interfaces/IPremiumLegacy.sol";
import "../interfaces/IPremiumSetting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PremiumMailActivated is OwnableUpgradeable {
  using FunctionsRequest for FunctionsRequest.Request;
  using FormatUnits for uint256;
  struct BeneReceived {
    string name;
    address beneAddress;
    string[] listAssetName;
    uint256[] listAmount;
  }

  struct ListAsset {
    address listToken;
    uint256 listAmount;
    string listAssetName;
  }

  //CHAINLINK FUNCTION
  address public router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
  bytes32 public donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
  uint64 public subscriptionId;

  //PREMIUM CONTRACT
  address public sendMailRouter; // the only contract can call send email

  //MAIL SERVICE
  string private constant authHeader = "";


  // State variables
  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  uint256 public mailId;

  //Callback gas limit
  uint32 public gasLimit = 300000;

  // email invoke name
  uint256 constant ACTIVATED_TO_BENE = 7217007;
  uint256 constant ACTIVATED_TO_BENE_WITH_REMAINING = 7217008;
  uint256 constant ACTIVATED_MULTISIG = 7217009;
  uint256 constant CONTRACT_ACTIVATED_TO_OWNER =  7217010;

  uint256 constant OWNER_RESET_TO_BENE = 7217011;
  uint256 constant OWNER_RESET_TO_LAYER2 = 7217011;
  uint256 constant OWNER_RESET_TO_LAYER3 = 7217011;

  // Custom error type
  error UnexpectedRequestID(bytes32 requestId);
  error OnlyRouterCanFulfill();

  // Event to log responses
  event Response(bytes32 indexed requestId, bytes response, bytes err);
  event RequestSent(bytes32 indexed id);
  event RequestFulfilled(bytes32 indexed id);
  event SendMail(string to, NotifyLib.NotifyType notifyType);

  modifier onlyRouter() {
    require(msg.sender == sendMailRouter, "Only router");
    _;
  }

  function initialize(address _router, uint64 _subscriptionId, bytes32 _donId, uint32 _gasLimit, address _sendMailRouter) public initializer {
    router = _router;
    subscriptionId = _subscriptionId;
    donID = _donId;
    gasLimit = _gasLimit;
    sendMailRouter = _sendMailRouter;
    __Ownable_init(msg.sender);
  }

  function setParams(address _router, uint64 _subscriptionId, bytes32 _donId, uint32 _gasLimit, address _sendMailRouter) external onlyOwner {
    router = _router;
    subscriptionId = _subscriptionId;
    donID = _donId;
    gasLimit = _gasLimit;
    sendMailRouter = _sendMailRouter;
  }

  /**
   * @notice Callback function for fulfilling a request
   * @param requestId The ID of the request to fulfill
   * @param response The HTTP response data
   * @param err Any errors from the Functions request
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal {
    if (s_lastRequestId != requestId) {
      revert UnexpectedRequestID(requestId);
    }
    s_lastResponse = response;
    s_lastError = err;
    emit Response(requestId, s_lastResponse, s_lastError);
  }

  function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err) external {
    require(msg.sender == router, "Only router can fulfill");
    fulfillRequest(requestId, response, err);
    emit RequestFulfilled(requestId);
  }

  function sendEmailActivatedToBene(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address[] memory listToken,
    uint256[] memory listAmount,
    string[] memory listAssetName,
    address contractAddress,
    bool remaining
  ) external onlyRouter {
    if (!remaining) {
      _sendEmailActivatedToBene(beneName, beneEmail, contractName, listToken, listAmount, listAssetName, contractAddress);
    } else {
      _sendEmailActivatedToBeneWithRemaining(beneName, beneEmail, contractName, listToken, listAmount, listAssetName, contractAddress);
    }
    _emitSendMail(beneEmail, NotifyLib.NotifyType.ContractActivated);
  }

  function sendEmailContractActivatedToOwner(
    string memory toEmail,
    string memory contractName,
    address activatedByBene,
    uint256 timeActivated,
    address safeWallet,
    ListAsset[] memory _listAsset,
    BeneReceived[] memory _listBeneReceived,
    address contractAddress,
    bool remaining
  ) external onlyRouter {
    _sendEmailContractActivatedToOwner(
      toEmail,
      contractName,
      activatedByBene,
      timeActivated,
      safeWallet,
      _listAsset,
      _listBeneReceived,
      contractAddress,
      remaining
    );
    _emitSendMail(toEmail, NotifyLib.NotifyType.ContractActivated);
  }

  function sendMailActivatedMultisig(
    string[] memory beneNames,
    string[] memory beneEmails,
    string memory contractName,
    address safeWallet
  ) external onlyRouter {
    for (uint256 i = 0; i < beneNames.length; i++) {
      if (bytes(beneEmails[i]).length > 0) {
        _sendActivatedMutisig(beneNames[i], beneEmails[i], contractName, safeWallet);
        _emitSendMail(beneEmails[i], NotifyLib.NotifyType.ContractActivated);
      }
    }
  }

  //Onwer Reset
  function sendMailOwnerResetToBene(string[] memory beneNames, string[] memory beneEmails, string memory contractName) external onlyRouter {
    for (uint256 i = 0; i < beneNames.length; i++) {
      if (bytes(beneEmails[i]).length > 0) {
        _sendEmailOwnerResetToBene(beneNames[i], beneEmails[i], contractName);
        _emitSendMail(beneEmails[i], NotifyLib.NotifyType.OwnerReset);
      }
    }
  }

  // common function
  function _sendEmailToAddressBegin(string memory to, string memory subject, uint256 templateId) private pure returns (string memory) {
    string memory formatEmailTo = string.concat(
      "const emailURL = 'https://api.mailjet.com/v3.1/send';",
      "const authHeader = 'Basic ",
      authHeader,
      "';",
      "const emailData = { Messages: ",
      "[ { From: {Email: 'app@10102.io', Name: '10102 Platform',},",
      "To: [ {Email: '",
      to,
      "', Name:'',},],",
      "TemplateID: ",
      Strings.toString(templateId),
      ", TemplateLanguage: true,",
      "Subject: '",
      subject,
      "',",
      "Variables: {"
    );
    return formatEmailTo;
  }

  function _sendEmailToAddressEnd() private pure returns (string memory) {
    string memory formatEmailEnd = string.concat(
      "},},],};",
      "const response = await Functions.makeHttpRequest({",
      "  url: emailURL,",
      "  method: 'POST',",
      "  headers: { 'Content-Type': 'application/json', 'Authorization': authHeader },",
      "  data: emailData",
      "});",
      "if (response.error) throw Error(`Failed to send email: ${JSON.stringify(response)}`);",
      "return Functions.encodeString('Email sent!');"
    );
    return formatEmailEnd;
  }

  //** Activated */
  // 1. To layer1
  // 2. To layer2

  function _sendEmailActivatedToBene(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address[] memory listToken,
    uint256[] memory listAmount,
    string[] memory listAssetName,
    address contractAddress
  ) internal returns (bytes32 requestId) {
    string memory listAsset = "listAsset: [";
    for (uint256 i = 0; i < listToken.length; i++) {
      address tokenAddr = listToken[i];
      uint8 decimals = tokenAddr != address(0) ? ERC20(tokenAddr).decimals() : 18;
      listAsset = string.concat(
        listAsset,
        "    {assetAddr: '",
        Strings.toHexString(tokenAddr),
        "', amount: '",
        listAmount[i].format(decimals),
        "', assetName: '",
        listAssetName[i],
        "' }"
      );
      if (i < listToken.length - 1) {
        listAsset = string.concat(listAsset, ",");
      }
    }
    listAsset = string.concat(listAsset, "]");

    string memory subject = string.concat("[", contractName, "] Activated - You have Received Your Inheritance");

    string memory params = string.concat(
      " bene_name: '",
      beneName,
      "',  contract_name: '",
      contractName,
      "',",
      listAsset,
      ", contract_address: '",
      Strings.toHexString(contractAddress),
      "'"
    );

    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, ACTIVATED_TO_BENE), params, _sendEmailToAddressEnd());

    return _sendRequest(source);
  }

  function _sendEmailActivatedToBeneWithRemaining(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address[] memory listToken,
    uint256[] memory listAmount,
    string[] memory listAssetName,
    address contractAddress
  ) internal returns (bytes32 requestId) {
    string memory subject = string.concat("[", contractName, "] Activated with Remaining Funds - You have Received Partial Inheritance");
    string memory listAsset = "listAsset: [";
    for (uint256 i = 0; i < listToken.length; i++) {
      address tokenAddr = listToken[i];
      uint8 decimals = tokenAddr != address(0) ? ERC20(tokenAddr).decimals() : 18;
      listAsset = string.concat(
        listAsset,
        "    {assetAddr: '",
        Strings.toHexString(tokenAddr),
        "', amount: '",
        listAmount[i].format(decimals),
        "', assetName: '",
        listAssetName[i],
        "' }"
      );
      if (i < listToken.length - 1) {
        listAsset = string.concat(listAsset, ",");
      }
    }
    listAsset = string.concat(listAsset, "]");

    string memory params = string.concat(
      "  bene_name: '",
      beneName,
      "',  contract_name: '",
      contractName,
      "',",
      listAsset,
      ", contract_address: '",
      Strings.toHexString(contractAddress),
      "'"
    );
    string memory source = string.concat(
      _sendEmailToAddressBegin(beneEmail, subject, ACTIVATED_TO_BENE_WITH_REMAINING),
      params,
      _sendEmailToAddressEnd()
    );
    return _sendRequest(source);
  }

  //** Contract activated */ Same email
  // 1. To owner
  // 2. To layer1

  function _sendEmailContractActivatedToOwner(
    string memory toEmail,
    string memory contractName,
    address activatedByBene,
    uint256 timeActivated,
    address safeWallet,
    ListAsset[] memory _listAsset,
    BeneReceived[] memory _listBeneReceived,
    address contractAddress,
    bool remaining
  ) internal returns (bytes32 requestId) {
    uint8 [] memory decimals = new uint8[](_listAsset.length); 
    string memory listAsset = "listAsset: [";
    for (uint256 i = 0; i < _listAsset.length; i++) {
      address tokenAddr = _listAsset[i].listToken;
      decimals[i] = _listAsset[i].listToken != address(0) ? ERC20(tokenAddr).decimals() : 18;
      listAsset = string.concat(
        listAsset,
        "    {assetAddr: '",
        Strings.toHexString(tokenAddr),
        "', amount: '",
        _listAsset[i].listAmount.format(decimals[i]),
        "', assetName: '",
        _listAsset[i].listAssetName,
        "' }"
      );
      if (i < _listAsset.length - 1) {
        listAsset = string.concat(listAsset, ",");
      }
    }
    listAsset = string.concat(listAsset, "]");

    string memory listBeneReceived = "listBeneficiaries: [";
    for (uint256 i = 0; i < _listBeneReceived.length; i++) {
      listBeneReceived = string.concat(
        listBeneReceived,
        "    {beneName: '",
        _listBeneReceived[i].name,
        "', beneAddr: '",
        Strings.toHexString(_listBeneReceived[i].beneAddress),
        "', amounts: '"
      );

      string memory listAssetAmount = "";
      for (uint256 j = 0; j < _listBeneReceived[i].listAmount.length; j++) {
        listAssetAmount = string.concat(
          listAssetAmount,
          (_listBeneReceived[i].listAmount[j]).format(decimals[j]),
          " ",
          _listBeneReceived[i].listAssetName[j],
          " "
        );
        if (j < _listBeneReceived[i].listAmount.length - 1) {
          listAssetAmount = string.concat(listAssetAmount, ",");
        }
      }
      listAssetAmount = string.concat(listAssetAmount, "' }");
      if (i < _listBeneReceived.length - 1) {
        listAssetAmount = string.concat(listAssetAmount, ",");
      }
      listBeneReceived = string.concat(listBeneReceived, listAssetAmount);
    }
    listBeneReceived = string.concat(listBeneReceived, "]");

    string memory subject = string.concat("[", contractName, "] Was Activated");

    string memory params = string.concat(
      " bene_addr: '",
      Strings.toHexString(activatedByBene),
      "',  contract_name: '",
      contractName,
      "',  active_date: new Date(",
      Strings.toString(timeActivated * 1000),
      "), safe_wallet: '",
      Strings.toHexString(safeWallet),
      "',",
      listAsset,
      ",",
      listBeneReceived,
      ", contract_address: '",
      Strings.toHexString(contractAddress),
      "', remaining: '",
      remaining ? "true'" : "false'"
    );

    string memory source = string.concat(_sendEmailToAddressBegin(toEmail, subject, CONTRACT_ACTIVATED_TO_OWNER), params, _sendEmailToAddressEnd());
    return _sendRequest(source);
  }

  function _sendActivatedMutisig(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address safeWallet
  ) internal returns (bytes32) {
    string memory subject = string.concat("You Have Been Added as a Co-Signer to the Safe Wallet for ", contractName);
    string memory params = string.concat(
      "bene_name: '",
      beneName,
      "', contract_name: '",
      contractName,
      "', safe_address: '",
      Strings.toHexString(safeWallet),
      "'"
    );
    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, ACTIVATED_MULTISIG), params, _sendEmailToAddressEnd());
    return _sendRequest(source);
  }

  function _sendEmailOwnerResetToBene(string memory beneName, string memory beneEmail, string memory contractName) internal returns (bytes32) {
    string memory subject = string.concat("The activation timeline of [", contractName, "] has been reset");
    string memory params = string.concat("bene_name: '", beneName, "', contract_name: '", contractName, "'");
    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, OWNER_RESET_TO_BENE), params, _sendEmailToAddressEnd());
    return _sendRequest(source);
  }

  function _sendRequest(string memory source) internal returns (bytes32) {
    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(source);
    s_lastRequestId = IFunctionsRouter(router).sendRequest(subscriptionId, req.encodeCBOR(), FunctionsRequest.REQUEST_DATA_VERSION, gasLimit, donID);
    return s_lastRequestId;
  }

  function _emitSendMail(string memory to, NotifyLib.NotifyType notifyType) internal {
    mailId++;
    emit SendMail(to, notifyType);
  }
}
