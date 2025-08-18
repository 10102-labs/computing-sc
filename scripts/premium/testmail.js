async function main() {
  const to = "thao.nguyen3@sotatek.com";
  const subject = "Test email";
  const message = "This is a test email";
  const timestamp = "1234234234";
  const lastTx = "1234234234";
  const sender = "0x223";
  const ownerEmail = "thao.nguyen3@sotatek.com";
  const contractName = "Legacy for testing";
  const ownerName = "Thao";
  const activateDate = "2025-07-16";
  const list = [1, 2, 3];

  let listString = JSON.stringify(list.map(String)); // ['1','2','3']

  const string =
    "const engagelabUrl = 'https://email.api.engagelab.cc/v1/mail/sendtemplate';" +
    "const authHeader = 'Basic " +
    "SkdkSEZSdUczUk5EX3Rlc3RfN1VUbWdJOjVjM2YyMzU4YTZkOTI0NmU1YzdhN2Q0ZDE0ODBkZjdi';" +
    "const emailData = { request_id: '" +
    timestamp +
    sender +
    "'," +
    "'from': 'EngageLab@dkyoa7dg6acjqgl7cqrc9yvbhd24z2mu.send.engagelab.email', 'to': ['" +
    ownerEmail +
    "'],  body: {" +
    "    subject: 'Reminder - [" +
    contractName +
    "] Nearing Activation'," +
    "template_invoke_name: '10102_to_owner'," +
    "dynamic_vars: [" +
    "    {owner_name: '" +
    ownerName +
    "'," +
    "    contract_name: '" +
    contractName +
    "'," +
    "    last_tx: '" +
    lastTx +
    "'," +
    "    activate_date: '" +
    activateDate +
    "'," +
    "    list: " +
    listString +
    "  }]}};" +
    "const response = await Functions.makeHttpRequest({" +
    "  url: engagelabUrl," +
    "  method: 'POST'," +
    "  headers: { 'Content-Type': 'application/json', 'Authorization': authHeader }," +
    "  data: emailData" +
    "});" +
    "if (response.error) throw Error('Failed to send email');" +
    "return Functions.encodeString('Email sent!');";

  console.log(string);
}

async function test() {
  const fetch = require("node-fetch"); // if Node < 18
  const base64 = Buffer.from("JGdHFRuG3RND_test_7UTmgI:5c3f2358a6d9246e5c7a7d4d1480df7b").toString("base64");

  console.log(base64);

  const emailData = {
    from: "EngageLab@dkyoa7dg6acjqgl7cqrc9yvbhd24z2mu.send.engagelab.email",
    to: ["thao.nguyen3@sotatek.com"],
    // request_id: 14,
    body: {
      subject: "Reminder - [Contract Name] Nearing Activation",
      template_invoke_name: "for_layer1_send_to_owner",
      // vars: {
      //   "%owner_name%": ["Thao"],
      //   "%contract_name%": ["Legacy for testing"],
      //   "%last_tx%": ["122113123"],
      //   "%activate_date%": ["2025-07-16"],
      //   "%list%": ["token1", "token2", "token3"],
      // },
      dynamic_vars: [
        {
          owner_name: "Thao",
          contract_name: "Legacy for testing",
          last_tx: "122113123xxxx",
          activate_date: new Date(1752662996848),
          list: ["user1", "user2", "user3"],
        },
      ],
    },
  };

  // fetch("https://email.api.engagelab.cc/v1/mail/sendtemplate", {
  //   method: "POST",
  //   headers: {
  //     "Content-Type": "application/json",
  //     Authorization: `Basic ${base64}`,
  //   },
  //   body: JSON.stringify(emailData),
  // })
  //   .then((res) => res.json())
  //   .then((data) => console.log("Email sent:", data))
  //   .catch((err) => console.error("Error:", err));
}

async function test2() {
  const fetch = require("node-fetch"); // if Node < 18
  const base64 = Buffer.from("JGdHFRuG3RND_test_7UTmgI:5c3f2358a6d9246e5c7a7d4d1480df7b").toString("base64");

  console.log(base64);

  const emailData = {
    from: "EngageLab@dkyoa7dg6acjqgl7cqrc9yvbhd24z2mu.send.engagelab.email",
    to: ["thao.nguyen3@sotatek.com"],
    request_id: "12 sdfd",
    body: {
      subject: "Reminder - [Contract Name] Nearing Activation",
      template_invoke_name: "activated_assets_received",
      // vars: {
      //   "%owner_name%": ["Thao"],
      //   "%contract_name%": ["Legacy for testing"],
      //   "%last_tx%": ["122113123"],
      //   "%activate_date%": ["2025-07-16"],
      //   "%list%": ["token1", "token2", "token3"],
      // },
      dynamic_vars: [
        {
          bene_name: "Thao",
          contract_name: "Legacy for testing",

          listAsset: [
            {
              asset: "ETH",
              amount: 100,
              asset_url: "https://www.google.com",
            },
            {
              asset: "BTC",
              amount: 200,
              asset_url: "https://www.google.com",
            },
          ],
        },
      ],
    },
  };

  fetch("https://email.api.engagelab.cc/v1/mail/sendtemplate", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${base64}`,
    },
    body: JSON.stringify(emailData),
  })
    .then((res) => res.json())
    .then((data) => console.log("Email sent:", data))
    .catch((err) => console.error("Error:", err));
}

async function createUsingMailJet() {
  const fetch = require("node-fetch"); // if Node < 18
  const base64 = Buffer.from("8ceab64afe115dbabb18a4d3803b1792:d4e04c2e517f5d320868bbb7948e6b39").toString("base64");

  console.log(base64);

  const emailData = {
    Messages: [
      {
        From: { Email: "thao.nguyen3@sotatek.com", Name: "10102 Platform" },
        To: [{ Email: "thao.nguyen3@sotatek.com", Name: "" }],
        TemplateID: 7180073,
        TemplateLanguage: true,
        Subject: "Get Ready - [Test] Will Be Ready to Activate Soon",
        Variables: { bene_name: "Test", contract_name: "Test", x_day_before_active: 8 },
        MessageUUID: "1234567890",
      },
    ],
  };

  fetch("https://api.mailjet.com/v3.1/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic OGNlYWI2NGFmZTExNWRiYWJiMThhNGQzODAzYjE3OTI6ZDRlMDRjMmU1MTdmNWQzMjA4NjhiYmI3OTQ4ZTZiMzk=`,
    },
    body: JSON.stringify(emailData),
  })
    .then((res) => res.json())
    .then((data) => console.log("Email sent:", data))
    .catch((err) => console.error("Error:", err));
}

// test2()
// ;

async function sendThirdlineReadyToActivate() {
  const fetch = require("node-fetch"); // if Node < 18
  const base64 = Buffer.from("8ceab64afe115dbabb18a4d3803b1792:d4e04c2e517f5d320868bbb7948e6b39").toString("base64");

  console.log(base64);

  const emailData = {
    Messages: [
      {
        From: { Email: "thao.nguyen3@sotatek.com", Name: "10102 Platform" },
        To: [{ Email: "dat.tran2@sotatek.com", Name: "Dat" }],
        TemplateID: 7190049,
        TemplateLanguage: true,
        Subject: "“[Test Contract]” Is Ready",
        Variables: {
          bene_name: "Dat",
          contract_name: "Test Contract",
          activation_date: "2025-08-01",
          new_bene: "0x1234...abcd"
        },
        MessageUUID: "1234567890"
      },
    ],
  };

  fetch("https://api.mailjet.com/v3.1/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic OGNlYWI2NGFmZTExNWRiYWJiMThhNGQzODAzYjE3OTI6ZDRlMDRjMmU1MTdmNWQzMjA4NjhiYmI3OTQ4ZTZiMzk=`,
    },
    body: JSON.stringify(emailData),
  })
    .then((res) => res.json())
    .then((data) => console.log("Email sent:", data))
 
}

async function sendEmailBeforeLayer3ToLayer12() {
  const fetch = require("node-fetch"); // if Node < 18
  const base64 = Buffer.from("8ceab64afe115dbabb18a4d3803b1792:d4e04c2e517f5d320868bbb7948e6b39").toString("base64");

  console.log(base64);

  const emailData = {
    Messages: [
      {
        From: { Email: "thao.nguyen3@sotatek.com", Name: "10102 Platform" },
        To: [{ Email: "dat.tran2@sotatek.com", Name: "Dat" }],
        TemplateID: 7179998,
        TemplateLanguage: true,
        Subject: "Reminder - Third-Line Activation for [Test Send Mail] Approaching",
        Variables: {
          bene_name: "Dat",
          contract_name: "Test Contract",
          x_days: "1 day",
          new_bene: "0x1234...abcd"
        },
        MessageUUID: "1234567890"
      },
    ],
  };

  fetch("https://api.mailjet.com/v3.1/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic OGNlYWI2NGFmZTExNWRiYWJiMThhNGQzODAzYjE3OTI6ZDRlMDRjMmU1MTdmNWQzMjA4NjhiYmI3OTQ4ZTZiMzk=`,
    },
    body: JSON.stringify(emailData),
  })
    .then((res) => res.json())
    .then((data) => console.log("Email sent:", data))
}

async function sendEmailBeforeLayer3ToLayer3() {
  const fetch = require("node-fetch"); // if Node < 18
  const base64 = Buffer.from("96270cbb8d25400307535bd6088eb896:e9217689e89f21cc3c7076bb337f6c51").toString("base64");

  console.log(base64);


  const emailData = {
    Messages: [
      {
        From: { Email: "dat.tran2@sotatek.com", Name: "10102 Platform" },
        To: [{ Email: "dat.tran2@sotatek.com", Name: "Dat" }],
        TemplateID: 7215893,
        TemplateLanguage: true,
        Subject: "You May Soon Be Eligible to Activate [Test Send Mail]",
        Variables: {
          bene_name: "Dat",
          contract_name: "Test Contract",
          x_days: "1 days",
          new_bene: "0x1234...abcd"
        },
        MessageUUID: "1234567890"
      },
    ],
  };

  fetch("https://api.mailjet.com/v3.1/send", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic OTYyNzBjYmI4ZDI1NDAwMzA3NTM1YmQ2MDg4ZWI4OTY6ZTkyMTc2ODllODlmMjFjYzNjNzA3NmJiMzM3ZjZjNTE=`,
    },
    body: JSON.stringify(emailData),
  })
    .then((res) => res.json())
    .then((data) => console.log("Email sent:", data))
}

// sendThirdlineReadyToActivate();
// sendEmailBeforeLayer3ToLayer12();
sendEmailBeforeLayer3ToLayer3();


async function test3() {
  const response = await Functions.makeHttpRequest({
    url: "http://example.com",
    method: "GET", // Optional
    // Other optional parameters
  });
}

// // const emailURL = "https://api.mailjet.com/v3.1/send";
// // const authHeader = "Basic OGNlYWI2NGFmZTExNWRiYWJiMThhNGQzODAzYjE3OTI6ZDRlMDRjMmU1MTdmNWQzMjA4NjhiYmI3OTQ4ZTZiMzk=";
// // const emailData = {
// //   Messages: [
// //     {
// //       From: { Email: "thao.nguyen3@sotatek.com", Name: "10102 Platform" },
// //       To: [{ Email: "thao.nguyen3@sotatek.com", Name: "" }],
// //       TemplateID: 7180073,
// //       TemplateLanguage: true,
// //       Subject: "Get Ready - [Test] Will Be Ready to Activate Soon",
// //       Variables: { bene_name: "Test", contract_name: "Test", x_day_before_active: 8 },
// //     },
// //   ],
// // };
// // const response = await Functions.makeHttpRequest({
// //   url: emailURL,
// //   method: "POST",
// //   headers: { "Content-Type": "application/json", Authorization: authHeader },
// //   data: emailData,
// // });
// // if (response.error) throw Error("Failed to send email", response.error);
// // return Functions.encodeString("Email sent!");

// const emailURL = "https://api.mailjet.com/v3.1/send";
// const authHeader = "Basic OGNlYWI2NGFmZTExNWRiYWJiMThhNGQzODAzYjE3OTI6ZDRlMDRjMmU1MTdmNWQzMjA4NjhiYmI3OTQ4ZTZiMzk=";
// const emailData = {
//   Messages: [
//     {
//       From: { Email: "thao.nguyen3@sotatek.com", Name: "10102 Platform" },
//       To: [{ Email: "thao.nguyen3@sotatek.com", Name: "" }],
//       TemplateID: 7180073,
//       TemplateLanguage: true,
//       Subject: "Get Ready - [Legcay Name] Will Be Ready to Activate Soon",
//       Variables: { bene_name: "Thao", contract_name: "Legcay Name", x_day_before_active: 7 },
//     },
//   ],
// };
// const response = await Functions.makeHttpRequest({
//   url: emailURL,
//   method: "POST",
//   headers: { "Content-Type": "application/json", Authorization: authHeader },
//   data: emailData,
// });
// if (response.error) throw Error(`Failed to send email: ${JSON.stringify(response)}`);
// return Functions.encodeString("Email sent!");


// // main();
