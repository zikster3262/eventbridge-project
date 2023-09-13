const AWS = require('aws-sdk');
const eventBridge = new AWS.EventBridge();

exports.handler = async (event, context) => {
  try {
    const body = JSON.parse(event.body);

    const params = {
      Entries: [
        {
          Source: 'custom.aws.replayer',
          DetailType: 'CustomEventType',
          Detail: JSON.stringify(body),
          EventBusName: process.env.EVENTBUS,
        },
      ],
    };

    console.log(JSON.stringify(params));

    await sendEventToEventBridge(params);

    console.log('Event sent successfully to EventBridge.');

    return {
      statusCode: 200,
      body: 'Event sent successfully to EventBridge.',
    };
  } catch (error) {
    console.error('Error sending event to EventBridge:', error);

    return {
      statusCode: 500,
      body: 'Error sending event to EventBridge.',
    };
  }
};

async function sendEventToEventBridge(params) {
  const maxRetries = parseInt(process.env.MAX_RETRIES) || 3;

  for (let retry = 1; retry <= maxRetries; retry++) {
    try {
      await eventBridge.putEvents(params).promise();
      return;
    } catch (error) {
      console.error(
        `Error sending event to EventBridge (attempt ${retry}/${maxRetries}):`,
        error
      );
    }
  }

  throw new Error(`Failed to send event to EventBridge after ${maxRetries} attempts.`);
}
