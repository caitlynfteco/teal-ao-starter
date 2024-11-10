import { readFileSync } from "node:fs";
import { message, result, createDataItemSigner, spawn } from "@permaweb/aoconnect";

// Load the wallet file
const wallet = JSON.parse(readFileSync("./wallet.json").toString(),);
const processId = "hc_Reja5MFGERT8eyPS1NRGxuKhuB-6vH5HIlMhsFYg"

const requestId                 = 4
const checkpoint_input          = "0xea6564a9e97c968d9502918d60aea4903f38d4a2831b11dd9be125883192a3f594765c9bcd5d1e508c0b94665929f78b215c7e0dff5134ce6c96344cb031cfad9a6573f8b180c6fdbfacfa30c15d244e29bdd9565eb69b9cf9b44d6fd176c891d6d028da538be5596ffcfb77bbb2b0c6045e7604731c8a33c6b67d3501c25c5b"
const modulus                   = "0x53d91575a1c293b7e0c07165618791ec7664382ed9ec0512b434481307d77f0ba9ce9b97a3121ea9ed8acc6db81b2c7e1c0da84aa5874a908559bcbbe32e535d2f840da5a4321ca68570dd0343be63be0092bef7fc6885595f1feb6ab107e73a7d30c50b4a636533c1f990af521e794c7379fe393bd87a2a8eeac0b26fc09c2bd04775983e2c6be6719f4c1dd727a5fab021c5e6736081fad42b297a84cad0e75491b6ed22b346aa04f9f18f0d37505e0c4f3cb4b48d6f01eeb6c8f332af5960769394cbdfefc8b494b53404222b8a95dd1624aba1887a779e813b98bbfcc9e3c03497ff87192b33e064caaf67317d06bab416cdeac1cafac05c3260b2361ebb"
const expected_output           = "0x2eeb5943f0fa07494fb0cd5b354a4b5b90d8e0475ec7e1dc1626fb61e819f6e31ba6c48db0c9d8f8d914732c69766149282a391b619d960c821a5c86ca4db33685b1de6a9edf63351b2a313c9498a7aae1ac64711765a6eb791f1b591023c52cb441c1accbc7a6c260858da972e339a08abcca9d7b35e167303356107f4dc383fdf66b2267c03fbf7f51cb53d5d21a9c495a8ef1598d7aac30ec7d32e4cf62b009f997a2f29fb6d9d4e867d890eb026c9057e2f9263aa2ef0dbcb514e4d1f3cff33a3da6255bd0d354906e86b605e57d77eef16f3a5c4689b1a2cc3f53387618ab8f64e467d07bd2d53004efa06070baf9c16f82a2bb48361d59cf356cd14ae3"


async function validate() {
    let tags = [
        { name: "Action", value: "Validate-Checkpoint" },
    ]

    let id = await message({
        /*-+
          The arweave TXID of the process, this will become the "target".
          This is the process the message is ultimately sent to.
        */
        process: processId,
        // Tags that the process will use as input.
        tags,
        // A signer function used to build the message "signature"
        signer: createDataItemSigner(wallet),
        /*
          The "data" portion of the message
          If not specified a random string will be generated
        */
        data: JSON.stringify({ requestId, checkpoint_input, modulus, expected_output }),
    })

    console.log(id)
    const { Output, Messages } = await result({
        message: id,
        process: processId,
    });
    
    if (Messages && Messages.length > 0) {
        const data = JSON.parse(Messages[0].Data);
        console.log("Status: ", data);
    }
    
    return id;
}

// Main function to call post data
async function main() {
    const inputArg =  process.argv[2];
    
    if (inputArg == 1) {
        try {
            await validate()
        } catch (err) {
            console.error("Error reading process IDs or sending messages:", err);
        }
    } 
}

main();