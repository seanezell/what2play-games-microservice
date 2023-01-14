/*
    What2Play::Games API::Add Games 
    Sean Ezell
*/

const AWS = require('aws-sdk');

exports.handler = async (event) => {
    // #region setup crap
    const DBClient = new AWS.DynamoDB.DocumentClient({
        apiVersion: "2012-08-10",
        region: "us-west-2",
    });
    // #endregion

    // #region putItem
    const params = {
        TableName: 'games',
        Item: {
            create_date: new Date().toISOString(),
            ...event
        },
        ConditionExpression: "game_name <> :game_name",
        ExpressionAttributeValues: {
            ":game_name" : event.game_name
        }
    };
    
    try {
        console.log('adding game '+event.game_name);
        await DBClient.put(params).promise();
    } catch (error) {
        console.error(error);
        throw JSON.stringify( {
            'statusCode': '500',
            'message': 'Failed to add the game. '+error
        });
    }
    // #endregion

    return {
        statusCode: 200,
        body: {
            status: 'SUCCESS',
            game_name: event.game_name
        }
    }
};