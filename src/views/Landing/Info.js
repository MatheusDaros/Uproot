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
    Jumbotron,
    Progress,
    Table,
    UncontrolledCarousel
} from "reactstrap";

const carouselItems = [
    {
        src: require("assets/img/denys.jpg"),
        altText: "Slide 1",
        caption: "Big City Life, United States"
    },
    {
        src: require("assets/img/fabien-bazanegue.jpg"),
        altText: "Slide 2",
        caption: "Somewhere Beyond, United States"
    },
    {
        src: require("assets/img/mark-finn.jpg"),
        altText: "Slide 3",
        caption: "Stocks, United States"
    }
];

let ps = null;

class Info extends React.Component {
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

                        <Container fluid>
                        
                        <h1 className="title text-center"><i className='fa fa-xl fa-rocket text-center'></i></h1>
                            <h1 className="title text-center">  Start Guide</h1>
                        </Container>

                    <Row className='justify-content-between mb-4'>
                        <Col md="4">
                            <h5 className="text-on-back">01</h5>
                            <h1 className="profile-title text-left">Create your onw Wallet</h1>
                            <p className="profile-description text-left">
                                An artist of considerable range, Ryan — the name taken by
                                Melbourne-raised, Brooklyn-based Nick Murphy — writes,
                                performs and records all of his own music, giving it a warm,
                                intimate feel with a solid groove structure. An artist of
                                considerable range.
                            </p>
                            <div className="btn-wrapper pt-3">
                                <Button
                                    className="btn-simple"
                                    color="primary"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-book-bookmark" /> Bookmark
                              </Button>
                                <Button
                                    className="btn-simple"
                                    color="info"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-bulb-63" /> Check it!
                              </Button>
                            </div>
                        </Col>
                        <Col md="4">
                            <h5 className="text-on-back">02</h5>
                            <h1 className="profile-title text-left">Connect with Metamask</h1>
                            <p className="profile-description text-left">
                                An artist of considerable range, Ryan — the name taken by
                                Melbourne-raised, Brooklyn-based Nick Murphy — writes,
                                performs and records all of his own music, giving it a warm,
                                intimate feel with a solid groove structure. An artist of
                                considerable range.
                            </p>
                            <div className="btn-wrapper pt-3">
                                <Button
                                    className="btn-simple"
                                    color="primary"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-book-bookmark" /> Bookmark
                              </Button>
                                <Button
                                    className="btn-simple"
                                    color="info"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-bulb-63" /> Check it!
                              </Button>
                            </div>
                        </Col>
                        <Col md="4">
                            <h5 className="text-on-back">03</h5>
                            <h1 className="profile-title text-left">Register in University</h1>
                            <p className="profile-description text-left">
                                An artist of considerable range, Ryan — the name taken by
                                Melbourne-raised, Brooklyn-based Nick Murphy — writes,
                                performs and records all of his own music, giving it a warm,
                                intimate feel with a solid groove structure. An artist of
                                considerable range.
                            </p>
                            <div className="btn-wrapper pt-3">
                                <Button
                                    className="btn-simple"
                                    color="primary"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-book-bookmark" /> Bookmark
                              </Button>
                                <Button
                                    className="btn-simple"
                                    color="info"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-bulb-63" /> Check it!
                              </Button>
                            </div>
                        </Col>
                    </Row>
                    <Row className='justify-content-between mb-4'>
                        <Col md="4">
                            <h5 className="text-on-back">04</h5>
                            <h1 className="profile-title text-left">Apply in a Classroom</h1>
                            <p className="profile-description text-left">
                                An artist of considerable range, Ryan — the name taken by
                                Melbourne-raised, Brooklyn-based Nick Murphy — writes,
                                performs and records all of his own music, giving it a warm,
                                intimate feel with a solid groove structure. An artist of
                                considerable range.
                            </p>
                            <div className="btn-wrapper pt-3">
                                <Button
                                    className="btn-simple"
                                    color="primary"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-book-bookmark" /> Bookmark
                              </Button>
                                <Button
                                    className="btn-simple"
                                    color="info"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-bulb-63" /> Check it!
                              </Button>
                            </div>
                        </Col>
                        <Col md="4">
                            <h5 className="text-on-back">05</h5>
                            <h1 className="profile-title text-left">Complete Classrooms</h1>
                            <p className="profile-description text-left">
                                An artist of considerable range, Ryan — the name taken by
                                Melbourne-raised, Brooklyn-based Nick Murphy — writes,
                                performs and records all of his own music, giving it a warm,
                                intimate feel with a solid groove structure. An artist of
                                considerable range.
                            </p>
                            <div className="btn-wrapper pt-3">
                                <Button
                                    className="btn-simple"
                                    color="primary"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-book-bookmark" /> Bookmark
                              </Button>
                                <Button
                                    className="btn-simple"
                                    color="info"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-bulb-63" /> Check it!
                              </Button>
                            </div>
                        </Col>
                        <Col md="4">
                            <h5 className="text-on-back">06</h5>
                            <h1 className="profile-title text-left">Earn Rewards and Grants</h1>
                            <p className="profile-description text-left">
                                An artist of considerable range, Ryan — the name taken by
                                Melbourne-raised, Brooklyn-based Nick Murphy — writes,
                                performs and records all of his own music, giving it a warm,
                                intimate feel with a solid groove structure. An artist of
                                considerable range.
                            </p>
                            <div className="btn-wrapper pt-3">
                                <Button
                                    className="btn-simple"
                                    color="primary"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-book-bookmark" /> Bookmark
                              </Button>
                                <Button
                                    className="btn-simple"
                                    color="info"
                                    href="#pablo"
                                    onClick={e => e.preventDefault()}
                                >
                                    <i className="tim-icons icon-bulb-63" /> Check it!
                              </Button>
                            </div>
                        </Col>
                    </Row>

                </Container>
            </>
        );
    }
}

export default Info;
