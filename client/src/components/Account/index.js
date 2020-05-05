import React, { useState, useEffect } from 'react';
import { Card, PublicAddress, Button, Heading, Text } from 'rimble-ui';
import { Container, Row, Col, Navbar, Nav, Form, FormControl } from 'react-bootstrap';

export default function Web3Info(props) {
  const { web3Context } = props;

  const [balance, setBalance] = useState(0);

  const getBalance = async web3Context => {
    const accounts = web3Context.accounts;
    const lib = web3Context.lib;
    let balance =
      accounts && accounts.length > 0 ? lib.utils.fromWei(await lib.eth.getBalance(accounts[0]), 'ether') : 'Unknown';
    setBalance(balance);
  };

  useEffect(() => {
    getBalance(web3Context);
  }, [web3Context, web3Context.accounts, web3Context.networkId]);

  const requestAuth = async web3Context => {
    try {
      await web3Context.requestAuth();
    } catch (e) {
      console.error(e);
    }
  };

  const { networkId, networkName, accounts, providerName } = web3Context;

  return (
    <>
      <Card>
        <Heading>
          <h3> {props.title} </h3>
        </Heading>
        <Text className="align-items-left text-left">
          <div>
            <div>Network:</div>
            <div>{networkId ? `${networkId} – ${networkName}` : 'No connection'}</div>
          </div>
          <div>
            <div>Your address:</div>
            <div>
              <PublicAddress label="" address={accounts && accounts.length ? accounts[0] : 'Unknown'} />
            </div>
          </div>
          <div>
            <div>Your ETH balance:</div>
            <div>{balance}</div>
          </div>
          <div>
            <div>Provider:</div>
            <div>{providerName}</div>
          </div>
          {accounts && accounts.length ? (
            <div>
              <div>Accounts & Signing Status</div>
              <div>Access Granted</div>
            </div>
          ) : !!networkId && providerName !== 'infura' ? (
            <div>
              <br />
              <Button onClick={() => requestAuth(web3Context)}>Conect Web3</Button>
            </div>
          ) : (
            <div></div>
          )}
        </Text>
      </Card>
    </>
  );
}
