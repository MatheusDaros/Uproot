import React from 'react';
import { Flex, Button, Card, Heading, Table, Box, Text } from 'rimble-ui';

class Classes extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      inputFocus: false,
    };
  }
  render() {
    return (
      <>
        <Flex>
          <Card>
            <Heading className="align-items-center">
              <h3>
                Classrooms
                <Button size="small" ml={4} mb={3}>
                  Create Classroom
                </Button>
              </h3>
            </Heading>
            <Text>
              <Table mr={4}>
                <thead>
                  <tr>
                    <th>Name</th>
                    <th className="text-center">Apply</th>
                    <th className="text-center">End</th>
                    <th className="text-center">Price</th>
                    <th className="text-center">Interest</th>
                    <th className="text-left"></th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>Learn Solidity</td>
                    <td className="text-center">05/05/2020</td>
                    <td className="text-center">06/10/2020</td>
                    <td className="text-center">400 DAI</td>
                    <td className="text-center">4,0%</td>
                    <td className="text-left">
                      <Button size="small" mr={3}>
                        Access
                      </Button>
                      {` `}
                    </td>
                  </tr>
                  <tr>
                    <td>Learn Solidity</td>
                    <td className="text-center">05/05/2020</td>
                    <td className="text-center">06/10/2020</td>
                    <td className="text-center">400 DAI</td>
                    <td className="text-center">4,0%</td>
                    <td className="text-left">
                      <Button size="small" mr={3}>
                        Access
                      </Button>
                      {` `}
                    </td>
                  </tr>
                  <tr>
                    <td>Learn Solidity</td>
                    <td className="text-center">05/05/2020</td>
                    <td className="text-center">06/10/2020</td>
                    <td className="text-center">400 DAI</td>
                    <td className="text-center">4,0%</td>
                    <td className="text-left">
                      <Button size="small" mr={3}>
                        Access
                      </Button>
                      {` `}
                    </td>
                  </tr>
                  <tr>
                    <td>Learn Solidity</td>
                    <td className="text-center">05/05/2020</td>
                    <td className="text-center">06/10/2020</td>
                    <td className="text-center">400 DAI</td>
                    <td className="text-center">4,0%</td>
                    <td className="text-left">
                      <Button size="small" mr={3}>
                        Access
                      </Button>
                      {` `}
                    </td>
                  </tr>
                  <tr>
                    <td>Learn Solidity</td>
                    <td className="text-center">05/05/2020</td>
                    <td className="text-center">06/10/2020</td>
                    <td className="text-center">400 DAI</td>
                    <td className="text-center">4,0%</td>
                    <td className="text-left">
                      <Button size="small" mr={3}>
                        Access
                      </Button>
                      {` `}
                    </td>
                  </tr>
                </tbody>
              </Table>
            </Text>
          </Card>
        </Flex>
      </>
    );
  }
}

export default Classes;
