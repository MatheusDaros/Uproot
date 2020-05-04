import React from "react";

// reactstrap components
import {
    Button,
    Badge,
    ButtonGroup,
    Container,
    Row,
    Col,
    Card,
    CardHeader,
    CardTitle,
    CardImg,
    CardBody,
    Progress,
    Table
} from "reactstrap";

class AllCourses extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            inputFocus: false
        };
    }
    render() {
        return (
                <>
                <Container>
                    <Row>
                        <Col>
                            <Table>
                                <thead>
                                    <tr>
                                        <th className="text-center">#</th>
                                        <th>Name</th>
                                        <th>Job Position</th>
                                        <th className="text-center">Since</th>
                                        <th className="text-right">Salary</th>
                                        <th className="text-right">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td className="text-center">1</td>
                                        <td>Andrew Mike</td>
                                        <td>Develop</td>
                                        <td className="text-center">2013</td>
                                        <td className="text-right">€ 99,225</td>
                                        <td className="text-right">
                                            <Button className="btn-icon" color="info" size="sm">
                                                <i className="fa fa-user"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="success" size="sm">
                                                <i className="fa fa-edit"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="danger" size="sm">
                                                <i className="fa fa-times" />
                                            </Button>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td className="text-center">1</td>
                                        <td>Andrew Mike</td>
                                        <td>Develop</td>
                                        <td className="text-center">2013</td>
                                        <td className="text-right">€ 99,225</td>
                                        <td className="text-right">
                                            <Button className="btn-icon" color="info" size="sm">
                                                <i className="fa fa-user"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="success" size="sm">
                                                <i className="fa fa-edit"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="danger" size="sm">
                                                <i className="fa fa-times" />
                                            </Button>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td className="text-center">1</td>
                                        <td>Andrew Mike</td>
                                        <td>Develop</td>
                                        <td className="text-center">2013</td>
                                        <td className="text-right">€ 99,225</td>
                                        <td className="text-right">
                                            <Button className="btn-icon" color="info" size="sm">
                                                <i className="fa fa-user"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="success" size="sm">
                                                <i className="fa fa-edit"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="danger" size="sm">
                                                <i className="fa fa-times" />
                                            </Button>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td className="text-center">1</td>
                                        <td>Andrew Mike</td>
                                        <td>Develop</td>
                                        <td className="text-center">2013</td>
                                        <td className="text-right">€ 99,225</td>
                                        <td className="text-right">
                                            <Button className="btn-icon" color="info" size="sm">
                                                <i className="fa fa-user"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="success" size="sm">
                                                <i className="fa fa-edit"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="danger" size="sm">
                                                <i className="fa fa-times" />
                                            </Button>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td className="text-center">1</td>
                                        <td>Andrew Mike</td>
                                        <td>Develop</td>
                                        <td className="text-center">2013</td>
                                        <td className="text-right">€ 99,225</td>
                                        <td className="text-right">
                                            <Button className="btn-icon" color="info" size="sm">
                                                <i className="fa fa-user"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="success" size="sm">
                                                <i className="fa fa-edit"></i>
                                            </Button>{` `}
                                            <Button className="btn-icon" color="danger" size="sm">
                                                <i className="fa fa-times" />
                                            </Button>
                                        </td>
                                    </tr>
                                </tbody>
                            </Table>
                        </Col>
                    </Row>

                </Container>
                </>
        );
    }
}

export default AllCourses;
