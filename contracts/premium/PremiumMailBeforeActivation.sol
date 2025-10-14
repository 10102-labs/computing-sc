// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/NotifyLib.sol";
contract PremiumMailBeforeActivation is OwnableUpgradeable {
  using FunctionsRequest for FunctionsRequest.Request;

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
  uint256 constant BEFORE_ACTIVATION_TO_OWNER = 7180104;
  uint256 constant BEFORE_ACTIVATION_TO_BENEFICIARY = 7180073;

  uint256 constant BEFORE_LAYER2_TO_OWNER = 7179589;
  uint256 constant BEFORE_LAYER2_TO_LAYER1 = 7180055;
  uint256 constant BEFORE_LAYER2_TO_LAYER2 = 7180019;

  uint256 constant BEFORE_LAYER3_TO_OWNER = 7180086;
  uint256 constant BEFORE_LAYER3_TO_LAYER12 = 7179998;
  uint256 constant BEFORE_LAYER3_TO_LAYER3 = 7179988;

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

  /**
   * @notice Callback function for fulfilling a request
   * @param requestId The ID of the request to fulfill
   * @param response The HTTP response data
   * @param err Any errors from the Functions request
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal {
    if (s_lastRequestId != requestId) {
      revert UnexpectedRequestID(requestId); // Check if request IDs match
    }
    // Update the contract's state variables with the response and any errors
    s_lastResponse = response;
    s_lastError = err;

    // Emit an event to log the response
    emit Response(requestId, s_lastResponse, s_lastError);
  }

  function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err) external {
    require(msg.sender == router, "Only router can fulfill");
    fulfillRequest(requestId, response, err);
    emit RequestFulfilled(requestId);
  }

  function sendEmailBeforeActivationToOwner(
    string memory ownerName,
    string memory contractName,
    uint256 lastTx,
    uint256 bufferTime,
    address[] memory listBene,
    string memory ownerEmail
  ) external onlyRouter {
    _sendEmailBeforeActivationToOwner(ownerName, contractName, lastTx, bufferTime, listBene, ownerEmail);
    _emitSendMail(ownerEmail, NotifyLib.NotifyType.BeforeActivation);
  }

  function sendEmailBeforeActivationToBeneficiary(
    string[] memory beneNames,
    string memory contractName,
    uint256 timeCountdown,
    string[] memory beneEmails
  ) external onlyRouter {
    for (uint256 i = 0; i < beneNames.length; i++) {
      if (bytes(beneEmails[i]).length > 0) {
        _sendEmailBeforeActivationToBeneficiary(beneNames[i], contractName, timeCountdown, beneEmails[i]);
        _emitSendMail(beneEmails[i], NotifyLib.NotifyType.BeforeActivation);
      }
    }
  }


  function sendEmailBeforeLayer2ToLayer1(
    string [] memory beneNames,
    string [] memory beneEmails,
    string memory contractName,
    uint256 x_days
  ) external onlyRouter {
    for (uint256 i = 0; i < beneNames.length; i++) {
      if (bytes(beneEmails[i]).length > 0) {
        _sendEmailBeforeLayer2ToLayer1(beneNames[i], beneEmails[i], contractName, x_days);
        _emitSendMail(beneEmails[i], NotifyLib.NotifyType.BeforeLayer2);
      }
    }
  }

  function sendEmailBeforeLayer2ToLayer2(string memory beneName, string memory beneEmail, string memory contractName, uint256 x_days) external onlyRouter {
    _sendEmailBeforeLayer2ToLayer2(beneName, beneEmail, contractName, x_days);
    _emitSendMail(beneEmail, NotifyLib.NotifyType.BeforeLayer2);
  }


  function sendEmailBeforeLayer3ToLayer12(
    string [] memory beneNames,
    string [] memory beneEmails,
    string memory contractName,
    uint256 x_day
  ) external onlyRouter {
    for (uint256 i = 0; i < beneNames.length; i++) {
      if (bytes(beneEmails[i]).length > 0) {
        _sendEmailBeforeLayer3ToLayer12(beneNames[i], beneEmails[i], contractName, x_day);
        _emitSendMail(beneEmails[i], NotifyLib.NotifyType.BeforeLayer3);
      }
    }
  }

  function sendEmailBeforeLayer3ToLayer3(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 x_day
  ) external onlyRouter {
    _sendEmailBeforeLayer3ToLayer3(beneName, beneEmail, contractName, x_day);
    _emitSendMail(beneEmail, NotifyLib.NotifyType.BeforeLayer3);
  }


  // common function
  function _sendEmailToAddressBegin(string memory to, string memory subject, uint256 templateId) private pure returns (string memory) {
    string memory formatEmailTo = string.concat(
      "const emailURL = 'https://api.mailjet.com/v3.1/send';",
      "const authHeader = 'Basic ",
      authHeader,
      "';",
      "const emailData = { Messages: ",
      "[ { From: {Email: 'thao.nguyen3@sotatek.com', Name: '10102 Platform',},",
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

  //** Send email BeforeActivation */ -> enum = 1

  // 1. To owner
  // 2. To beneficiary

  function _sendEmailBeforeActivationToOwner(
    string memory ownerName,
    string memory contractName,
    uint256 lastTx,
    uint256 bufferTime,
    address[] memory listBene,
    string memory ownerEmail
  ) public returns (bytes32 requestId) {
    string memory subject = string.concat("Reminder - [", contractName, "] Nearing Activation");
    string memory listString = "list: [";
    for (uint256 i = 0; i < listBene.length; i++) {
      listString = string.concat(listString, "'", Strings.toHexString(listBene[i]), "'");
      if (i < listBene.length - 1) {
        listString = string.concat(listString, ",");
      }
    }
    listString = string.concat(listString, "]");

    string memory params = string.concat(
      "owner_name: '",
      ownerName,
      "', contract_name: '",
      contractName,
      "', last_tx: new Date(",
      Strings.toString(lastTx * 1000),
      "),  activate_date: '",
      Strings.toString(bufferTime / 86400),
      " day(s)',",
      listString
    );

    string memory source = string.concat(_sendEmailToAddressBegin(ownerEmail, subject, BEFORE_ACTIVATION_TO_OWNER), params, _sendEmailToAddressEnd());

    return _sendRequest(source);
  }

  function _sendEmailBeforeActivationToBeneficiary(
    string memory beneName,
    string memory contractName,
    uint256 timeCountdown,
    string memory beneEmail
  ) public returns (bytes32 requestId) {
    string memory subject = string.concat("Get Ready - [", contractName, "] Will Be Ready to Activate Soon");

    string memory params = string.concat(
      "bene_name: '",
      beneName,
      "', contract_name: '",
      contractName,
      "',  x_day_before_active: ",
      Strings.toString(timeCountdown)
    );

    string memory source = string.concat(
      _sendEmailToAddressBegin(beneEmail, subject, BEFORE_ACTIVATION_TO_BENEFICIARY),
      params,
      _sendEmailToAddressEnd()
    );

    return _sendRequest(source);
  }

  //Befor layer 2
  //1.To layer 1
  //2.To layer 2


  function _sendEmailBeforeLayer2ToLayer1(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 x_days
  ) public returns (bytes32 requestId) {
    string memory subject = string.concat("Reminder - Second-Line Activation for - [", contractName, "] Approaching");

    string memory params = string.concat(
      "bene_name: '",
      beneName,
      "',",
      "    contract_name: '",
      contractName,
      "',",
      "    x_days: '",
      Strings.toString(x_days),
      " day(s)',"
    );

    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, BEFORE_LAYER2_TO_LAYER1), params, _sendEmailToAddressEnd());
    return _sendRequest(source);
  }

  function _sendEmailBeforeLayer2ToLayer2(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 x_days
  ) public returns (bytes32 requestId) {
    string memory subject = string.concat("You May Soon Be Eligible to Activate [", contractName, "]");

    string memory params = string.concat("bene_name: '", beneName, "',  contract_name: '", contractName, "', x_days: '", Strings.toString(x_days), " day(s)'");

    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, BEFORE_LAYER2_TO_LAYER2), params, _sendEmailToAddressEnd());

    return _sendRequest(source);
  }

  //Befor layer 3
  //1.To layer 12
  //2.To layer 3

  function _sendEmailBeforeLayer3ToLayer12(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 x_day
  ) public returns (bytes32 requestId) {
    string memory subject = string.concat("Reminder - Third-Line Activation for [", contractName, "] Approaching");

    string memory params = string.concat(
      "bene_name: '",
      beneName,
      "',  contract_name: '",
      contractName,
      "',  x_days: '",
      Strings.toString(x_day),
      " day(s)',"
    );

    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, BEFORE_LAYER3_TO_LAYER12), params, _sendEmailToAddressEnd());

    return _sendRequest(source);
  }

  function _sendEmailBeforeLayer3ToLayer3(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 x_day
  ) public returns (bytes32 requestId) {
    string memory subject = string.concat("You May Soon Be Eligible to Activate [", contractName, "]");

    string memory params = string.concat(
      "bene_name: '",
      beneName,
      "',  contract_name: '",
      contractName,
      "',  x_days: '",
      Strings.toString(x_day),
      " day(s)',"
    );

    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, BEFORE_LAYER3_TO_LAYER3), params, _sendEmailToAddressEnd());

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
