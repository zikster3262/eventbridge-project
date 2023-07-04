const AWS = require('aws-sdk')

const eventBridge = new AWS.EventBridge()

exports.handler = async (event, context) => {
  try {
    // Validate the incoming event
    if (!event.body) {
      throw new Error('Missing event body.')
    }

    const body = JSON.parse(event.body)

    // Prepare the event parameters
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

    // Call EventBridge API with retries
    const result = await putEventsWithRetries(params)

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

async function putEventsWithRetries (params) {
  for (let retry = 1; retry <= process.env.MAX_RETRIES; retry++) {
    try {
      await eventBridge.putEvents(params).promise()
      return
    } catch (error) {
      console.error(
        `Error sending event to EventBridge (attempt ${retry}/${maxRetries}):`,
        error
      )
    }
  }

  throw new Error(
    `Failed to send event to EventBridge after ${maxRetries} attempts.`
  )
}
