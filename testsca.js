const child_process_1 = require("child_process");
const scaAgentToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NDMzMDk3LCJleHAiOjE3MTQ5OTg1MDYsImF1dGhvcml0aWVzIjoiQUdFTlQiLCJqdGkiOiIxMjdlYzhhZi03NDFiLTRjOWUtOWNjNC02NjE4N2ExNTk4ODciLCJjbGllbnRfaWQiOiIiLCJzY29wZSI6W119.JO_vDK-cCMwVWkz0Jt-1TvIE40PfcUeTeqdURyEnA_1KQUmHOfHPDHPOYeVJ1TfPpKo8gImUIBdggTpkj-g-C_QQ0y4CizJG_wBtJLRqJE5M_Wa9U_foX4GS8RqIiyNg9yaKVXhcUmkaU42cnA3lWCDcBPUEw8BAMfsxjOCeOx0'
//const scaAgentUrl = 'https://sca.analysiscenter.veracode.com/portfolio'
const scaAgentUrl = "https://api.sourceclear.io"
const scanDir = ''
let scaScanCommand = "";
let scaParams = "";
let scaScanCommandcurl = ""
scaScanCommand = 'bash ' + __dirname + '/sca-agent-LATEST/ci.sh -s scan --json=sca_results.json --allow-dirty --recursive'

scaScanCommandcurl = 'curl -sSL https://download.sourceclear.com/ci.sh | sh --debug'
let fs = require('fs')
//const sca_scan_results_1 = require("./sca-scan-results");

// let sca_scan_process;

//  sca_scan_process = (0, child_process_1.exec)(scaScanCommand, { env: { 'SRCCLR_API_TOKEN': scaAgentToken,  'SRCCLR_API_URL': scaAgentUrl, 'SCAN_DIR': scanDir},maxBuffer: undefined}, (error, stdout, stderr) => {
//     //sca_scan_process = (0, child_process_1.exec)(scaScanCommand, { env: { 'SRCCLR_API_TOKEN': scaAgentToken,  'SRCCLR_API_URL': scaAgentUrl} }, (error, stdout, stderr) => {

//     console.log("child process output",stdout)
//     console.log("child process error",error)
//     if (error) {
//         console.log(error)
//         console.log('sca scan error code: ' + error.code);
//         console.log('sca scan error name: ' + error.name);
//         console.log('sca scan error message: ' + error.cmd);
//     }
//     // console.log(`stdout: ${stdout}`);
//     // console.error(`stderr: ${stderr}`);
//     console.log(' INFO: Software Composition Analysis - Scan finished (Duration was ' + Date.now());

// })
let scaResult = {
    scan : "sca",
    filename: "sca_results.json"
}
// let noVulFlag = 0
// const findings = fs.readFileSync("sca_results.json", "utf8");
// const res = JSON.parse(findings.toString());
// let recNum = 0;
// console.log("res length",res.records.length)
//     for (let i = 0; i < res.records.length; i++) {
//         console.log("initial for loop", i)
//         if (res.records[i].metadata.recordType === "SCAN") {
//             recNum = i;
//             break;
//         }
//     }
// console.log(recNum)

//      if(res.records[recNum].vulnerabilities.length == 0){
//         scaResult.result = "No Vulneribilities Found"
//         scaResult.status = "Success";
       
//         }
//         else{
//             scaResult.result = findings.toString();
//   scaResult.status = "Findings";
//         }
    // if(recNum == 0){
    //     if(res.records[0].vulnerabilities.length == 0){
    //         scaResult.result = "No Vulneribilities Found"
    //     scaResult.status = "Success";
       
    //     }
    // }
    // else{
    //     for (let i = 0; i < res.records[recNum].vulnerabilities.length; i++) {
    //         console.log("inside for loop", i)
    //     if (res.records[recNum].vulnerabilities.length == 0){
    //         continue;
    //     }
    //     else{
            
    //         noVulFlag++;
    //         break;
    //     }
    // }
    // }
    console.log("data")
  
    

    

    console.log("scarResult",scaResult)
// let scaReport;
// let policyFile = "";
// scaReport = (0, sca_scan_results_1.processSCAResults)(policyFile);
// console.log("scaReport",scaReport)
console.log("testing the pull request")