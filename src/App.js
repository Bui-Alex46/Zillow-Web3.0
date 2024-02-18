import { useEffect, useState } from 'react';
import { ethers } from 'ethers';

// Components
import Navigation from './components/Navigation';
import Search from './components/Search';
import Home from './components/Home';

// ABIs
import RealEstate from './abis/RealEstate.json'
import Escrow from './abis/Escrow.json'

// Config
import config from './config.json';

function App() {

  // Providers
  const[provider, setProvider] = useState(null)

  const [escrow, setEscrow] = useState(null)
  // Accounts
  const [account , setAccount] = useState(null)

  // Homes
  const [homes, setHomes] = useState([])
  const [home, setHome] = useState({})
  const [toggle, setToggle] = useState(false)
  

  // Connecting react project to the blockchain using ethers js provider
  const loadBlockchainData = async () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum)
    setProvider(provider)

    const network = await provider.getNetwork()

    // Connect smart-contracts addresses using ethers js passing networkID, ABI, and provider
    const realEstate = new ethers.Contract(config[network.chainId].realEstate.address, RealEstate, provider )
    const totalSupply = await realEstate.totalSupply()
    const homes = []

    // Adding metadata to homes array 
    for ( var i = 1; i <= totalSupply; i++){
      const uri = await realEstate.tokenURI(i)
      const response = await fetch(uri)
      const metadata = await response.json()
      homes.push(metadata)
    }
    setHomes(homes)

    // Connect escrow smart contract 
    const escrow = new ethers.Contract(config[network.chainId].escrow.address, Escrow, provider )
    setEscrow(escrow)


    // Refetch accounts when you switch accounts 
    window.ethereum.on('accountsChanged', async () => {
      const accounts = await window.ethereum.request({method: 'eth_requestAccounts'});
      const account = ethers.utils.getAddress(accounts[0])
      setAccount(account)
    })
  }
// Use effect to call the blockchain data function
  useEffect(() => {
    loadBlockchainData()
  }, [])

const toggleProp = (home) => {
  setHome(home)
  toggle ? setToggle(false) : setToggle(true)
}

  return (
    <div>
      {/* Passing state variables to Navigation component */}
      <Navigation account = {account} setAccount = {setAccount}/>
      <Search />
      <div className='cards__section'>

        <h3>Homes For You</h3>
        <hr />
          <div className = 'cards'>
              {homes.map((home, index) => (
                  <div className = 'card' key = {index} onClick = {() => toggleProp(home)}> 
                  <div className = 'card__image'>
                      <img src = {home.image} alt = "Home"></img>
                  </div>
                  <div className = 'card__info'>
                      <h4 >{home.attributes[0].value} ETH</h4>
                      <p>
                        <strong>{home.attributes[2].value}</strong> bds |
                        <strong>{home.attributes[3].value}</strong> ba |
                        <strong>{home.attributes[4].value}</strong> sqft
                      </p>
                      <p>{home.address}</p>
                    </div>
                  </div>
            ))}
            
          </div>
        
      </div>
        {toggle && (
          <Home home = {home} provider = {provider} account = {account} escrow = {escrow} togglePop = {toggleProp}/>
        )}
    </div>
  );
}

export default App;
