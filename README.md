# Meritic Smart contracts

This repository includes Meritic's  implementation of  service smart contracts for creating stablecoin-backed Semi-Fungible tokens that hold time and service credits for creators and service providers. Our implementation adopts ERC-3525 Semi-Fungible Token standard. 
Thus service contracts are ERC-3525 - compatible Ethereum smart contracts.   

A creator configures and deploys his service contracts, enabling the creator / service  to issue credits, via tokens, to users, followers, or customers. Our implementation includes smart contracts for the following types of credits.

* Time credit: grants the token holder access to a duration of time reserved with the creator or service provider for (service reservations and tokenized meeting calendars).
* Cash credit: grants the  token holder a specified amount of cash-equivalent credits that can only be redeemed at the service or contract slot network of services. 
* Items credit: each token grants the holder access to a quantity of a specific item or offering.
* Priority credit: Each token holds a position in a queue or waitlist. 

Our implementation also introduces slot networks by creating the Registry, which enables multiple service contracts from different services to share a single ERC-3525 slotId. This feature means token holders can access multiple services using one token and that independent creators / services can package or pool their offerings into a packaged offering by joining and issuing tokens on a common slot. 

Development is on-going / incomplete. 

## Documentation
Visit for up to date docs: https://docs.meritic.xyz
## License
[Business Source License 1.1](https://mariadb.com/bsl11/)  and [MIT License] (https://github.com/solv-finance/erc-3525/blob/main/LICENSE) (see LICENSE.txt)

## Learn More
[Meritic ](/https://meritic.xyz) 

[ERC-3525 Standard ](https://eips.ethereum.org/EIPS/eip-3525) 

[ERC-3525 Reference implementation (Solv Finance) ](https://github.com/solv-finance/erc-3525)) 


```shell
npx hardhat compile
npx hardhat test
```
