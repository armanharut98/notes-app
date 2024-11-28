exports.handler = async (event) => {
    console.log("Lambda function invoked!")
    return {
        status: 200,
        body: "Hello from Lambda!"
    }
}
