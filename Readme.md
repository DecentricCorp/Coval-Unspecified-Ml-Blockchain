## Circuits of Value (http://cov.al) + Unspecified (http://unspecified.life)
## Blockchain and Machine Learning Collaboration

---

### Machine Learning technologies

- Python
- Gym
- Universe
- World of Bits

### Blockchain technologies

- NodeJS
- Ethereum
- Test RPC
- Coval-Solidity

---

### Executive Summary

Using Test RPC We create a light weight ethereum emulator to deploy smart contracts into.

We next deploy the ClickButton Contract using the Coval-Solidity Deployment CLI Tool

We then start the REST server from the CLI allowing interaction with the deployed contracts.

Next (having previously set up a working gym environment we run click.py)

Click.py loads the `wob.mini.ClickButton-v0` environment to begin training a model to be able to click the button requested.

Each iteration of a task records the PointerEvent's within ethereum storage for later retrieval and and historical purposes.

Click.py communicates with the contract via REST over http