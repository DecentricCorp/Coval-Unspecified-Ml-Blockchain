# Example Scenario & Contract

## Sample.sol
This contract is a simple data storage contract.
```javascript
pragma solidity ^0.4.9;

contract Sample {
    uint storedData;

    function set(uint x) {
        storedData = x;
    }

    function get() constant returns (uint x) {
        return storedData;
    }
}
```

## Sample.yaml
This scenario file first deploys the `Sample.sol` contract and then calls the `set` method on the deployed contract (setting the stored value to 50)

```yaml
# 
# Sample 
# 

# Create contract Sample
- contract:
    name: Sample
    dir: contracts/
    sources:
      - Sample.sol
    args: []

# Call method set(uint)
- where: 'Sample'
  call: set(uint)
  args:
    - '50'    

```