import { Card, Row, Col } from "antd"
import {
  LockOutlined,
  InboxOutlined,
  CarOutlined,
  MobileOutlined,
} from "@ant-design/icons"
import { StyleConstants } from "../styles/styleConstants"

/**
 * HomePageFeaturesComponent - Displays a grid of feature cards highlighting smart living amenities
 * Uses Ant Design's Card, Row, and Col components for responsive layout
 * Is used on the Home Page under the Hero Section
 */
const HomePageFeaturesComponent = () => {
  // Array of features with properties for title, icon, and description
  // TODO: Should we add more features? Like images or something
  const features = [
    {
      title: "Smart Door Locks",
      icon: <LockOutlined className="fs-2 text-primary mb-3" />,
      description:
        "Access your apartment securely through our mobile app. Grant temporary access to guests or maintenance with just a tap.",
    },
    {
      title: "Smart Package Lockers",
      icon: <InboxOutlined className="fs-2 text-success mb-3" />,
      description:
        "Never miss a delivery with our secure smart lockers. Receive instant notifications when packages arrive.",
    },
    {
      title: "Guest Parking Management",
      icon: <CarOutlined className="fs-2 text-warning mb-3" />,
      description:
        "Easily register guest vehicles and manage parking permits through our convenient digital system.",
    },
    {
      title: "Resident Portal",
      icon: <MobileOutlined className="fs-2 text-info mb-3" />,
      description:
        "Manage your entire resident experience from our website - pay rent, submit maintenance requests, and control smart home features.",
    },
  ]

  return (
    <div className="py-5 bg-light" style={{ margin: "50px 0px" }}>
      <div className="container">
        {/* Title */}
        <h2 className="text-center mb-5 fw-bold">Smart Living</h2>
        {/* Grid of feature cards */}
        <Row
          gutter={[StyleConstants.XS_BREAKPOINT, StyleConstants.XS_BREAKPOINT]}
        >
          {features.map((feature, index) => (
            <Col
              xs={StyleConstants.XS_BREAKPOINT}
              sm={StyleConstants.SM_BREAKPOINT}
              lg={StyleConstants.LG_BREAKPOINT}
              key={index}
            >
              {/* Start of Card (Card displays the feature) */}
              <Card
                hoverable
                className="h-100 text-center"
                style={{ minHeight: "280px" }}
              >
                <div className="d-flex flex-column align-items-center">
                  {/* Icon */}
                  {feature.icon}
                  {/* Title */}
                  <h4 className="mb-3">{feature.title}</h4>
                  {/* Description */}
                  <p className="text-muted">{feature.description}</p>
                </div>
              </Card>
            </Col>
          ))}
        </Row>
      </div>
    </div>
  )
}

export default HomePageFeaturesComponent
