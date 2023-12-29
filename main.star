network = import_module(
    "github.com/piwonskp/startnet/main.star"
)


CMD = """curl {} -s -X POST -H "Content-Type: application/json" --data '{{"method":"starknet_chainId","params":[],"id":1,"jsonrpc":"2.0"}}' | jq"""

RPC_URL = "{}://{}:{}/rpc/v0_6"


def run(plan, args={}):
    output = network.run(plan, {"participants": [{"type": "papyrus"}, {"type": "juno"}]})

    plan.add_service(
        name="tester",
        config=ServiceConfig(
            image="badouralix/curl-jq",
            cmd=["sleep", "infinity"]
        ),
    )
    papyrus_address = RPC_URL.format(output[0].ports["rpc"].application_protocol, output[0].ip_address, output[0].ports["rpc"].number)
    papyrus_out = plan.exec(
        service_name="tester",
        recipe=ExecRecipe(
            [
                "/bin/sh",
                "-c",
                "{} | tee /tmp/papyrus.json".format(CMD.format(papyrus_address))
            ]
        ),
    )

    juno_address = RPC_URL.format(output[1].ports["rpc"].application_protocol, output[1].ip_address, output[1].ports["rpc"].number)
    juno_out = plan.exec(
        service_name="tester",
        recipe=ExecRecipe(
            [
                "/bin/sh",
                "-c",
                "{} | tee /tmp/juno.json".format(CMD.format(juno_address))
            ]
        ),
    )

    plan.exec(
        service_name="tester",
        recipe=ExecRecipe(
            [
                "/bin/sh",
                "-c",
                "diff <(jq --sort-keys . /tmp/papyrus.json) <(jq --sort-keys . /tmp/juno.json)"
            ]
        ),
    )
