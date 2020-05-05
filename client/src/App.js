import React from 'react';
import Web3 from 'web3';

import { useWeb3Injected, useWeb3Network } from '@openzeppelin/network/react';

import { PublicAddress, Button } from 'rimble-ui';
import { Breadcrumb, Container, Row, Col, Card, Navbar, Nav, NavDropdown, Form, FormControl } from 'react-bootstrap';

import Web3Info from './components/Account/index.js';
import Classes from './components/University/Classes.js';
import Register from './components/Account/Register.js';

const infuraToken = '95202223388e49f48b423ea50a70e336';

function App() {
  const injected = useWeb3Injected();
  //const isHttp = window.location.protocol === 'http:';
  //const local = useWeb3Network('http://127.0.0.1:8545');
  //const network = useWeb3Network(`wss://ropsten.infura.io/ws/v3/${infuraToken}`, {
  //  pollInterval: 10 * 1000,
  //});

  return (
    <>
      <Navbar collapseOnSelect expand="lg" bg="dark" variant="dark">
        <Navbar.Brand href="#home">DeEd</Navbar.Brand>
        <Navbar.Toggle aria-controls="responsive-navbar-nav" />
        <Navbar.Collapse id="responsive-navbar-nav">
          <Nav className="mr-auto">
            <Nav.Link href="#university">University</Nav.Link>
            <Nav.Link href="#account">Account</Nav.Link>
            <Nav.Link href="#faq">Secretary</Nav.Link>
          </Nav>
          <Nav>
            <Button onClick={''}>Register</Button>
          </Nav>
        </Navbar.Collapse>
      </Navbar>
      <Container className="mt-4" fluid>
        <Row>
          <Col md={8}>
            <Classes />
          </Col>
          <Col md={4}>{injected && <Web3Info title="Conect To Web3" web3Context={injected} />}</Col>
        </Row>
        <Row>
          <Col md={12}>full</Col>
        </Row>
        <Row>
          <Col md={6}></Col>
          <Col md={6}></Col>
        </Row>
      </Container>
    </>
  );
}

export default App;
