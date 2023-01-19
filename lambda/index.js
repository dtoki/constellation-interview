// Description: Lambda function that returns a promise that prints "Hello World" to the console

exports.handler = async function(event) {
  const promise = new Promise(function(resolve, reject) {
    console.log("Hello World")
    })
    
  return promise
}
