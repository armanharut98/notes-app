exports.handler = async (event) => {
    console.log(`Lambda function invoked! Event: ${JSON.stringify(event)}`)
    return {
        status: 200,
        body: "Hello from Lambda!"
    }
}
