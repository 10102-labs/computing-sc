// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/NotifyLib.sol";

contract PremiumMailReadyToActivate is OwnableUpgradeable {
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

  uint256 constant READY_TO_ACTIVATE_TO_BENE = 7180118;

  uint256 constant READY_TO_ACTIVATE_LAYER2_TO_LAYER1 = 7180042;
  uint256 constant READY_TO_ACTIVATE_LAYER2_TO_LAYER2 = 7180010;

  uint256 constant READY_TO_ACTIVATE_LAYER3_TO_LAYER3 = 7179981;
  uint256 constant READY_TO_ACTIVATE_LAYER3_TO_LAYER12 = 7190049;

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

  constructor () {
    _disableInitializers();
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

  function sendEmailReadyToActivateToLayer1(string[] memory beneName, string[] memory beneEmail, string memory contractName) external onlyRouter {
    for (uint256 i = 0; i < beneName.length; i++) {
      if (bytes(beneEmail[i]).length > 0) {
        _sendEmailReadyToActivateToLayer1(beneName[i], beneEmail[i], contractName);
        _emitSendMail(beneEmail[i], NotifyLib.NotifyType.ReadyToActivate);
      }
    }
  }

  function sendEmailReadyToActivateLayer2ToLayer1(
    string[] memory beneNameLayer1,
    string[] memory beneEmailLayer1,
    address beneAddressLayer2,
    string memory contractName,
    uint256 timeActiveLayer2
  ) external onlyRouter {
    for (uint256 i = 0; i < beneNameLayer1.length; i++) {
      if (bytes(beneEmailLayer1[i]).length > 0) {
        _sendEmailReadyToActivateLayer2ToLayer1(beneNameLayer1[i], beneEmailLayer1[i], beneAddressLayer2, contractName, timeActiveLayer2);
        _emitSendMail(beneEmailLayer1[i], NotifyLib.NotifyType.Layer2ReadyToActivate);
      }
    }
  }

  function sendEmailReadyToActivateLayer2ToLayer2(
    string memory beneName,
    string memory beneEmail,
    string memory contractName
  ) external onlyRouter returns (bytes32 requestId) {
    string memory subject = string.concat("You May Now Activate the [", contractName, "]");
    string memory params = string.concat("bene_name: '", beneName, "', contract_name: '", contractName, "'");
    string memory source = string.concat(
      _sendEmailToAddressBegin(beneEmail, subject, READY_TO_ACTIVATE_LAYER2_TO_LAYER2),
      params,
      _sendEmailToAddressEnd()
    );
    return _sendRequest(source);
  }

  function sendEmailReadyToActivateLayer3ToLayer12(
    string[] memory beneNames,
    string[] memory beneEmails,
    string memory contractName,
    uint256 activationDate,
    address layer3Addr
  ) external onlyRouter {
    for (uint256 i = 0; i < beneNames.length; i++) {
      if (bytes(beneEmails[i]).length > 0) {
        _sendEmailReadyToActivateLayer3ToLayer12(beneNames[i], beneEmails[i], contractName, activationDate, layer3Addr);
        _emitSendMail(beneEmails[i], NotifyLib.NotifyType.Layer3ReadyToActivate);
      }
    }
  }
  function sendEmailReadyToActivateLayer3ToLayer3(
    string memory beneName,
    string memory beneEmail,
    string memory contractName
  ) external onlyRouter returns (bytes32 requestId) {
    string memory subject = string.concat("You May Now Activate the [", contractName, "]");
    string memory params = string.concat("bene_name: '", beneName, "', contract_name: '", contractName, "'");
    string memory source = string.concat(
      _sendEmailToAddressBegin(beneEmail, subject, READY_TO_ACTIVATE_LAYER3_TO_LAYER3),
      params,
      _sendEmailToAddressEnd()
    );
    _emitSendMail(beneEmail, NotifyLib.NotifyType.Layer3ReadyToActivate);
    return _sendRequest(source);
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

  /**Ready to activate */
  function _sendEmailReadyToActivateToLayer1(
    string memory beneName,
    string memory beneEmail,
    string memory contractName
  ) internal returns (bytes32 requestId) {
    string memory subject = string.concat("[", contractName, "] Is Ready to Activate");
    string memory params = string.concat("bene_name: '", beneName, "',  contract_name: '", contractName, "'");
    string memory source = string.concat(_sendEmailToAddressBegin(beneEmail, subject, READY_TO_ACTIVATE_TO_BENE), params, _sendEmailToAddressEnd());
    return _sendRequest(source);
  }

  function _sendEmailReadyToActivateLayer2ToLayer1(
    string memory beneNameLayer1,
    string memory beneEmailLayer1,
    address beneAddressLayer2,
    string memory contractName,
    uint256 timeActiveLayer2
  ) internal returns (bytes32 requestId) {
    string memory subject = string.concat("[", contractName, "] Is Ready");

    string memory params = string.concat(
      "bene_name: '",
      beneNameLayer1,
      "',",
      "    contract_name: '",
      contractName,
      "',",
      "    date: new Date(",
      Strings.toString(timeActiveLayer2*1000), //unixtimestamp in miliseconds
      "), address: '",
      Strings.toHexString(beneAddressLayer2),
      "'"
    );

    string memory source = string.concat(
      _sendEmailToAddressBegin(beneEmailLayer1, subject, READY_TO_ACTIVATE_LAYER2_TO_LAYER1),
      params,
      _sendEmailToAddressEnd()
    );

    return _sendRequest(source);
  }

  function _sendEmailReadyToActivateLayer3ToLayer12(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 activationDate,
    address layer3Addr
  ) internal returns (bytes32 requestId) {
    string memory subject = string.concat('"', contractName, '" Is Ready');

    string memory activationDateStr = Strings.toString(activationDate*1000); //unix timestamp in miliseconds
    string memory layer3AddrStr = Strings.toHexString(layer3Addr);

    string memory params = string.concat(
      "bene_name: '",
      beneName,
      "', contract_name: '",
      contractName,
      "', activation_date: new Date(",
      activationDateStr,
      "), new_bene: '",
      layer3AddrStr,
      "'"
    );

    string memory source = string.concat(
      _sendEmailToAddressBegin(beneEmail, subject, READY_TO_ACTIVATE_LAYER3_TO_LAYER12),
      params,
      _sendEmailToAddressEnd()
    );

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
