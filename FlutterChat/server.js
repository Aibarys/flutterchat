const users = { };
const rooms = { };
const io = require("socket.io")(require("http").createServer(function() {}).listen(80));

io.on("connection", io => {
    console.log("Connection established with a client");

    io.on("validate", (inData, inCallback) => {
        console.log("\n\nMSG: validate");
        console.log(`inData = ${JSON.stringify(inData)}`);

        const user = users[inData.userName];
        console.log(`user = ${JSON.stringify(user)}`);

        if (user) {
            if (user.password === inData.password) {
                console.log(`user = ${JSON.stringify(user)}`);
                inCallback({ status : "ok" });
            } else {
                console.log("Password incorrect");
                inCallback({ status : "fail" });
            }
        } else {
            console.log("User created");
            console.log(`users = ${JSON.stringify(users)}`);
            users[inData.userName] = inData;
            console.log(`users =${JSON.stringify(users)}`);
            io.broadcast.emit("newUser", users);
            inCallback({ status : "created"});
        }
    });




});

