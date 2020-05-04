import React from "react";
import classnames from "classnames";

// reactstrap components
import {
  Button,
  Card,
  CardHeader,
  CardBody,
  Label,
  FormGroup,
  Form,
  Input,
  FormText,
  NavItem,
  NavLink,
  Nav,
  Table,
  TabContent,
  TabPane,
  Container,
  Row,
  Col,
  UncontrolledTooltip,
  UncontrolledCarousel,
  Jumbotron
} from "reactstrap";

import AllCourses from "views/Landing/AllCourses";

class Profile extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tabs: 1
    };
  }

  toggleTabs = (e, stateName, index) => {
    e.preventDefault();
    this.setState({
      [stateName]: index
    });
  };
  render() {
    return (
      <>
        <Container className='mb-4' fluid>
        </Container>
        <Container className='align-items-center' fluid>
          <Row>
            <Col className='ml-auto mr-auto mt-4' lg="6" md="6">
              <Card className="card-coin card-plain">
                <CardHeader>
                  <h2 className="title">Account</h2>
                </CardHeader>
                <CardBody>
                  <Nav
                    className="nav-tabs-warning justify-content-center"
                    tabs
                  >
                    <NavItem>
                      <NavLink
                        className={classnames({
                          active: this.state.tabs === 1
                        })}
                        onClick={e => this.toggleTabs(e, "tabs", 1)}
                        href="#pablo"
                      >
                        Status
                          </NavLink>
                    </NavItem>
                    <NavItem>
                      <NavLink
                        className={classnames({
                          active: this.state.tabs === 2
                        })}
                        onClick={e => this.toggleTabs(e, "tabs", 2)}
                        href="#pablo"
                      >
                        Log
                          </NavLink>
                    </NavItem>
                  </Nav>
                  <TabContent
                    className="tab-subcategories"
                    activeTab={"tab" + this.state.tabs}
                  >
                    <TabPane tabId="tab1">
                      <Row>
                        <Label sm="3">Pay to</Label>
                        <Col sm="9">
                          <FormGroup>
                            <Input
                              placeholder="e.g. 1Nasd92348hU984353hfid"
                              type="text"
                            />
                            <FormText color="default" tag="span">
                              Please enter a valid address.
                                </FormText>
                          </FormGroup>
                        </Col>
                      </Row>
                      <Row>
                        <Label sm="3">Amount</Label>
                        <Col sm="9">
                          <FormGroup>
                            <Input placeholder="1.587" type="text" />
                          </FormGroup>
                        </Col>
                      </Row>
                      <Button
                        className="btn-simple btn-icon btn-round float-right"
                        color="primary"
                        type="submit"
                      >
                        <i className="tim-icons icon-send" />
                      </Button>
                    </TabPane>
                    <TabPane tabId="tab2">
                      <Table className="tablesorter">
                        <thead className="text-primary">
                          <tr>
                            <th className="header">Latest Activity</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr>
                            <td>Log 1...</td>
                          </tr>
                          <tr>
                            <td>Log 2...</td>
                          </tr>
                          <tr>
                            <td>Log 3...</td>
                          </tr>
                          <tr>
                            <td>Log 4...</td>
                          </tr>
                          <tr>
                            <td>Log 5...</td>
                          </tr>
                        </tbody>
                      </Table>
                    </TabPane>
                  </TabContent>
                </CardBody>
              </Card>
            </Col>
            <Col className='ml-auto mr-auto mt-4' lg="6" md="6">
              <Card className="card-coin card-plain">
                <CardHeader>
                  <h2 className="title">User Courses</h2>
                </CardHeader>
                <CardBody>
                  <AllCourses />
                </CardBody>
              </Card>
            </Col>
          </Row>
        </Container>
      </>
    );
  }
}

export default Profile;
