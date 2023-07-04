const AWS = require('aws-sdk')
const eventBridge = new AWS.EventBridge()

exports.handler = async (event, context) => {
  // The event object that you want to send to the event bus
  let body = JSON.parse(event.body)

  try {
    // Call the AWS SDK to put the event to the EventBridge event bus

    const params = {
      Entries: [
        {
          Source: 'custom.aws.replayer',
          DetailType: 'CustomEventType',
          Detail: JSON.stringify(body),
          EventBusName: process.env.EVENTBUS
        }
      ]
    }

    console.log(JSON.stringify(params))

    await eventBridge.putEvents(params).promise()
    console.log('Event sent successfully to EventBridge.')

    return {
      statusCode: 200,
      body: 'Event sent successfully to EventBridge.'
    }
  } catch (error) {
    console.error('Error sending event to EventBridge:', error)
    return {
      statusCode: 500,
      body: 'Error sending event to EventBridge.'
    }
  }
}
