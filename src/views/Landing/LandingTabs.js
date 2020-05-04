/*!

=========================================================
* BLK Design System React - v1.1.0
=========================================================

* Product Page: https://www.creative-tim.com/product/blk-design-system-react
* Copyright 2020 Creative Tim (https://www.creative-tim.com)
* Licensed under MIT (https://github.com/creativetimofficial/blk-design-system-react/blob/master/LICENSE.md)

* Coded by Creative Tim

=========================================================

* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

*/
import React from "react";
import classnames from "classnames";
// reactstrap components
import {
  TabContent,
  TabPane,
  Container,
  Row,
  Col,
  Card,
  CardHeader,
  CardBody,
  Nav,
  NavItem,
  NavLink
} from "reactstrap";

import AllCourses from "views/Landing/AllCourses";
import Courses from "views/Landing/Courses";
import Profile from "views/User/Profile";
import Secretary from "views/Secretary/Info";

class LandingTabs extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      pills: 1
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
      <div className="section section-tabs">
        <Container fluid>
          <Row>
            <Col className="ml-auto mr-auto" md="12" xl="12">
              <Card>
                <CardHeader>
                <Nav className='nav-pills-warning nav-pills-icons align-items-center' pills>
                <NavItem>
                  <NavLink
                    className={classnames({
                      "active show": this.state.pills === 1
                    })}
                    onClick={e => this.toggleTabs(e, "pills", 1)}
                    href="#university"
                  >
                    <i className="tim-icons icon-planet" />
                    University
                  </NavLink>
                </NavItem>
                <NavItem>
                  <NavLink
                    className={classnames({
                      "active show": this.state.pills === 2
                    })}
                    onClick={e => this.toggleTabs(e, "pills", 2)}
                    href="#classes"
                  >
                    <i className="tim-icons icon-atom" />
                    Classes
                  </NavLink>
                </NavItem>
                <NavItem>
                  <NavLink
                    className={classnames({
                      "active show": this.state.pills === 3
                    })}
                    onClick={e => this.toggleTabs(e, "pills", 3)}
                    href="#account"
                  >
                    <i className="tim-icons icon-single-02" />
                    Alummini
                  </NavLink>
                </NavItem>
                <NavItem>
                  <NavLink
                    className={classnames({
                      "active show": this.state.pills === 4
                    })}
                    onClick={e => this.toggleTabs(e, "pills", 4)}
                    href="#Info"
                  >
                    <i className="tim-icons icon-support-17" />
                    Secretary
                  </NavLink>
                </NavItem>
              </Nav>
                </CardHeader>
                <CardBody>
                  <TabContent
                    className="tab-space"
                    activeTab={"link" + this.state.pills}
                  >
                    <TabPane tabId="link1">
                    
                    </TabPane>
                    <TabPane tabId="link2">
                    <Courses/>
                    <AllCourses/>
                    </TabPane>
                    <TabPane tabId="link3">
                    <Profile/>
                    </TabPane>
                    <TabPane tabId="link4">
                    <Secretary/>
                    </TabPane>
                  </TabContent>
                </CardBody>
              </Card>
            </Col>
            </Row>

        </Container>
      </div>
    );
  }
}

export default LandingTabs;
