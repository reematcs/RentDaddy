import { useState } from "react"
import { useMutation } from "@tanstack/react-query"
import { Link } from "react-router"
import { Button, ConfigProvider, theme } from "antd"
import HeroBanner from "./components/HeroBanner"
import HomePageFeaturesComponent from "./components/HomePageFeaturesComponent"
import DemoTestingComponent from "./components/DemoTestingComponent";

function App() {
  return (
    <>
      <HeroBanner />
      <HomePageFeaturesComponent />
      <Link className="" to="/">
        <h4>RentDaddy</h4>
      </Link>

      <div className="d-flex flex-column">
        <Link to="/reusable-components">
          <Button type="primary" className="my-2">
            Checkout the Reusable Components
          </Button>
        </Link>

        {/* Login Button */}
        <Link to="/auth/login">
          <Button type="primary" className="my-2">
            Login
          </Button>
        </Link>

        {/* Admin Button */}
        <Link to="/admin">
          <Button className="my-2">Admin</Button>
        </Link>

        {/* Tenant Button */}
        <Link to="/tenant">
          <Button className="my-2">Tenant</Button>
        </Link>
      </div>

      <Items />
    </>
  )
}


export default App
