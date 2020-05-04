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

class Courses extends React.Component {
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
                            <Card>
                                <CardHeader><h1>Learn Solidity</h1>
                                    <Badge href="#" color="success">Beginner</Badge>
                                    <p className='mt-2'>Its had resolving otherwise she contented therefore. Afford relied warmth out sir hearts sister use garden.</p> </CardHeader>
                                <CardBody className='mt-0'>
                                    <Row>
                                        <Col className="px-2 py-2" lg="12" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="3" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-spaceship text-warning" />
                                                            </div>
                                                        </Col>
                                                        <Col md="9" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">May, 27</CardTitle>
                                                                <p />
                                                                <p className="card-category">Start Date</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                    </Row>
                                    <Row>
                                        <Col className="px-2 py-2" lg="6" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="4" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-coins text-info" />
                                                            </div>
                                                        </Col>
                                                        <Col md="8" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">400</CardTitle>
                                                                <p />
                                                                <p className="card-category">Dai</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                        <Col className="px-2 py-2" lg="6" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="4" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-gift-2 text-success" />
                                                            </div>
                                                        </Col>
                                                        <Col md="8" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">5%</CardTitle>
                                                                <p />
                                                                <p className="card-category">Interest</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                    </Row>
                                    <div className="text-center">75%</div>
                                    <Progress color="success" className='mb-4' value={75} />
                                    <Button className='btn btn-block mb-4' color="info">Apply Now</Button>{' '}
                                </CardBody>
                            </Card>
                        </Col>
                        <Col>
                            <Card>
                                <CardHeader><h1>Learn Solidity</h1>
                                    <Badge href="#" color="success">Beginner</Badge>
                                    <p className='mt-2'>Its had resolving otherwise she contented therefore. Afford relied warmth out sir hearts sister use garden.</p> </CardHeader>
                                <CardBody className='mt-0'>
                                    <Row>
                                        <Col className="px-2 py-2" lg="12" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="3" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-spaceship text-warning" />
                                                            </div>
                                                        </Col>
                                                        <Col md="9" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">May, 27</CardTitle>
                                                                <p />
                                                                <p className="card-category">Start Date</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                    </Row>
                                    <Row>
                                        <Col className="px-2 py-2" lg="6" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="4" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-coins text-info" />
                                                            </div>
                                                        </Col>
                                                        <Col md="8" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">400</CardTitle>
                                                                <p />
                                                                <p className="card-category">Dai</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                        <Col className="px-2 py-2" lg="6" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="4" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-gift-2 text-success" />
                                                            </div>
                                                        </Col>
                                                        <Col md="8" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">5%</CardTitle>
                                                                <p />
                                                                <p className="card-category">Interest</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                    </Row>
                                    <div className="text-center">75%</div>
                                    <Progress color="success" className='mb-4' value={75} />
                                    <Button className='btn btn-block mb-4' color="info">Apply Now</Button>{' '}
                                </CardBody>
                            </Card>
                        </Col>
                        <Col>
                            <Card>
                                <CardHeader><h1>Learn Solidity</h1>
                                    <Badge href="#" color="success">Beginner</Badge>
                                    <p className='mt-2'>Its had resolving otherwise she contented therefore. Afford relied warmth out sir hearts sister use garden.</p> </CardHeader>
                                <CardBody className='mt-0'>
                                    <Row>
                                        <Col className="px-2 py-2" lg="12" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="3" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-spaceship text-warning" />
                                                            </div>
                                                        </Col>
                                                        <Col md="9" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">May, 27</CardTitle>
                                                                <p />
                                                                <p className="card-category">Start Date</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                    </Row>
                                    <Row>
                                        <Col className="px-2 py-2" lg="6" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="4" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-coins text-info" />
                                                            </div>
                                                        </Col>
                                                        <Col md="8" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">400</CardTitle>
                                                                <p />
                                                                <p className="card-category">Dai</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                        <Col className="px-2 py-2" lg="6" sm="12">
                                            <Card className="card-stats">
                                                <CardBody>
                                                    <Row>
                                                        <Col md="4" xs="5">
                                                            <div className="icon-big text-center icon-warning">
                                                                <i className="tim-icons icon-gift-2 text-success" />
                                                            </div>
                                                        </Col>
                                                        <Col md="8" xs="7">
                                                            <div className="numbers">
                                                                <CardTitle tag="p">5%</CardTitle>
                                                                <p />
                                                                <p className="card-category">Interest</p>
                                                            </div>
                                                        </Col>
                                                    </Row>
                                                </CardBody>
                                            </Card>
                                        </Col>
                                    </Row>
                                    <div className="text-center">75%</div>
                                    <Progress color="success" className='mb-4' value={75} />
                                    <Button className='btn btn-block mb-4' color="info">Apply Now</Button>{' '}

                                </CardBody>
                            </Card>
                        </Col>
                    </Row>
                </Container>
            </>
        );
    }
}

export default Courses;
