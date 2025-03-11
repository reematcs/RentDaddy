import Icon, { ToolOutlined, WarningOutlined, InboxOutlined, CalendarOutlined, UserOutlined, CarOutlined } from "@ant-design/icons";
import { Tag } from "antd";
import React from "react";
import { Link } from "react-router";
import ModalComponent from "./ModalComponent";
import AlertComponent from "./reusableComponents/AlertComponent";
import ButtonComponent from "./reusableComponents/ButtonComponent";
import { CardComponent } from "./reusableComponents/cardComponent";

export const TenantDashBoard = () => {
    const handleOpenLocker = () => {
        console.log("Package added successfully");
        // Add your logic for adding a package here
    };

    return (
        <div className="container">
            <h1 className="my-4">Admin Dashboard</h1>
            <AlertComponent
                message="Welcome to the Tenant Dashboard"
                description="Sign Yo Lease. Pay Daddy Rent"
                type="warning"
            />
            {/* Dashboard Statistics Cards */}
            <h2 className="my-3">Quick Actions</h2>
            <div className="d-flex gap-4 my-5 w-100 justify-content-between">
                <CardComponent
                    title="Open Complaint form"
                    value={10}
                    description="Something not working right or disturbing you? Let us know."
                    hoverable={true}
                    icon={<ToolOutlined className="icon" />}
                    button={
                        <Link to="/tenant/admin-view-and-edit-work-orders-and-complaints">
                            <ButtonComponent
                                title="View All"
                                type="primary"
                                onClick={() => {}}
                            />
                        </Link>
                    }
                />
                <CardComponent
                    title="Package info"
                    value={10}
                    description="You have a package, head to your locker and click the button to open it"
                    hoverable={true}
                    icon={<InboxOutlined className="icon" />}
                    button={
                        // this should be the modal stuff
                        <ButtonComponent
                            title="Open Locker"
                            type="primary"
                            onClick={() => {
                                console.log("modal should open");
                                handleOpenLocker();
                            }}
                        />
                    }
                />
                <CardComponent
                    title="Guest Parking"
                    value={10}
                    description="Got a guest coming to visit? Make sure they have spots to park"
                    hoverable={true}
                    icon={<CarOutlined className="icon" />}
                    button={
                        // this should be the modal stuff
                        <ButtonComponent
                            title="Sign up guest"
                            type="primary"
                            onClick={() => {
                                console.log("modal should open");
                            }}
                        />
                    }
                />
            </div>
            {/* Quick access cod */}
            <h2 className="mb-3">Quick Access Documents Section</h2>
            <div className="d-flex gap-4 my-5 w-100 justify-content-between">
                <CardComponent
                    title={"Lease"}
                    description={"View or Resign your lease"}
                    hoverable={true}
                    button={
                        <ButtonComponent
                            title="Renew"
                            type="primary"
                            onClick={() => {
                                console.log("open user lease to sign");
                            }}
                        />
                    }
                />
                <CardComponent
                    title={"Work Order"}
                    description={<Tag color="orange">In Progress</Tag>}
                    hoverable={true}
                    button={
                        <ButtonComponent
                            title="View Details"
                            type="primary"
                            onClick={() => {
                                console.log("open work order");
                            }}
                        />
                    }
                />
                <CardComponent
                    title={"Complaint Received"}
                    description={`Our office received your complaint and will investiage immediately. "From: onegreatuser@hotmail.com: there are loud techo raves every night, even m..."`}
                    hoverable={true}
                    button={
                        <ButtonComponent
                            title="View Details"
                            type="primary"
                            onClick={() => {
                                console.log("open work order");
                            }}
                        />
                    }
                />
                <CardComponent
                    title={"Work Order"}
                    description={<Tag color="green">Done</Tag>}
                    hoverable={true}
                    button={
                        <ButtonComponent
                            title="View Details"
                            type="primary"
                            onClick={() => {
                                console.log("open work order");
                            }}
                        />
                    }
                />
                <CardComponent
                    title={"Work Order"}
                    description={<Tag color="green">Done</Tag>}
                    hoverable={true}
                    button={
                        <ButtonComponent
                            title="View Details"
                            type="primary"
                            onClick={() => {
                                console.log("open work order");
                            }}
                        />
                    }
                />
            </div>
        </div>
    );
};
