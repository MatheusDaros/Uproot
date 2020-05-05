import React, { useState, useEffect } from 'react';
import {
  PublicAddress,
  Card,
  Heading,
  Box,
  Form,
  Input,
  Select,
  Flex,
  Field,
  Button,
  Text,
  Checkbox,
  Radio,
} from 'rimble-ui';
import { Container, Row, Col } from 'react-bootstrap';

export default function Register(props) {
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

  const [formValidated, setFormValidated] = useState(false);
  const [validated, setValidated] = useState(false);
  const [inputValue, setInputValue] = useState('');
  const [formInputValue, setFormInputValue] = useState('');
  const [selectValue, setSelectValue] = useState('');
  const [checkboxValue, setCheckboxValue] = useState(false);
  const [radioValue, setRadioValue] = useState('');

  const handleInput = e => {
    setInputValue(e.target.value);
    validateInput(e);
  };

  const handleFormInput = e => {
    setFormInputValue(e.target.value);
    validateInput(e);
  };

  const handleSelect = e => {
    setSelectValue(e.target.value);
    validateInput(e);
  };

  const handleCheckbox = e => {
    setCheckboxValue(!checkboxValue);
    validateInput(e);
  };

  const handleRadio = e => {
    setRadioValue(e.target.value);
    validateInput(e);
  };

  const validateInput = e => {
    e.target.parentNode.classList.add('was-validated');
  };

  const validateForm = () => {
    // Perform advanced validation here
    if (inputValue.length > 0 && selectValue.length > 0 && checkboxValue === true && radioValue.length > 0) {
      setValidated(true);
    } else {
      setValidated(false);
    }
  };

  useEffect(() => {
    validateForm();
  });

  const handleSubmit = e => {
    e.preventDefault();
    console.log('Submitted valid form');
  };

  return (
    <>
      <Container fluid>
        <Row>
          <Col>
            <Card>
              <Heading>
                <h3> {props.title} </h3>
              </Heading>
              <Form onSubmit={handleSubmit} validated={formValidated}>
                <Flex mx={-3} flexWrap={'wrap'}>
                  <Box width={[1, 1, 1 / 2]} px={3}>
                    <Field label="Name" validated={validated} width={1}>
                      <Input
                        type="text"
                        required // set required attribute to use brower's HTML5 input validation
                        onChange={handleInput}
                        value={inputValue}
                        width={1}
                      />
                    </Field>
                  </Box>
                  <Box width={[1, 1, 1 / 2]} px={3}>
                    <Field label="Email" validated={validated} width={1}>
                      <Form.Input
                        type="email"
                        required // set required attribute to use brower's HTML5 input validation
                        onChange={handleFormInput}
                        value={formInputValue}
                        width={1}
                      />
                    </Field>
                  </Box>
                </Flex>
                <Flex mx={-3} flexWrap={'wrap'}>
                  <Box width={[1, 1, 1 / 2]} px={3}>
                    <Field label="Select Input" validated={validated} width={1}>
                      <Select
                        options={[
                          { value: '', label: '' },
                          { value: 'eth', label: 'Ethereum' },
                          { value: 'btc', label: 'Bitcoin' },
                          { value: 'gno', label: 'Gnosis' },
                          { value: 'gnt', label: 'Golem' },
                          { value: 'rep', label: 'Augur' },
                        ]}
                        value={selectValue}
                        onChange={handleSelect}
                        required // set required attribute to use brower's HTML5 input validation
                        width={1}
                      />
                    </Field>
                  </Box>
                </Flex>
                <Box>
                  <Field label="Address" address={accounts && accounts.length ? accounts[0] : 'Unknown'}>
                    <Form.Check
                      value={checkboxValue}
                      onChange={handleCheckbox}
                      required // set required attribute to use brower's HTML5 input validation
                    />
                  </Field>
                </Box>
                <Box>
                  {/* Use the validated state to update UI */}
                  <Button type="submit" disabled={!validated}>
                    Register
                  </Button>
                </Box>
              </Form>
            </Card>
          </Col>
        </Row>
      </Container>
    </>
  );
}
