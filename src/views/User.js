import React from "react";

// core components
import IndexNavbar from "components/Navbars/IndexNavbar.js";
import PageHeader from "components/PageHeader/PageHeader.js";
import Footer from "components/Footer/Footer.js";

//Tapioca
import Courses from "views/Landing/Courses.js";
import Profile from "views/User/Profile.js";

class User extends React.Component {
  componentDidMount() {
    document.body.classList.toggle("index-page");
  }
  componentWillUnmount() {
    document.body.classList.toggle("index-page");
  }
  render() {
    return (
      <>
        <IndexNavbar />
        <div className="wrapper">
            <PageHeader />
          <div className="main">
            <Profile />
            <Courses />
          </div>
          <Footer />
        </div>
      </>
    );
  }
}

export default User;
