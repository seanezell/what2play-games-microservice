/*

*/

exports.handler = async (event) => {
    return {
        statusCode: 200,
        body: "Sean was here "+event.dumb
    }
};