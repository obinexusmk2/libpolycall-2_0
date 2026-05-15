// SQUARE binding demo for Node.js
function submitTransaction(accountId, amount) {
  return { guid: "seeded-guid-demo", status: "accepted", accountId, amount };
}

if (require.main === module) {
  console.log(submitTransaction("A-100", 120.5));
}

module.exports = { submitTransaction };
