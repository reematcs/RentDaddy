import "../styles/styles.scss";

import { Tag } from "antd";
import ModalComponent from "../components/ModalComponent";
import TableComponent from "../components/reusableComponents/TableComponent";
import ButtonComponent from "../components/reusableComponents/ButtonComponent";
import type { ColumnsType } from "antd/es/table/interface";
import AlertComponent from "../components/reusableComponents/AlertComponent";

const AdminWorkOrder = () => {
    const handleAddWorkOrder = () => {
        console.log("Added package successfully.")
    };

    const handleAddComplaint = () => {
        console.log("Added complaint successfully.")
    };

    const workOrders: ColumnsType<{ roomNumber: string; name: string; leaseStatus: string }> = [
        { title: "Name", dataIndex: "roomNumber" },
        { title: "Room Number", dataIndex: "name" },
        {
            title: "Lease Status",
            dataIndex: "leaseStatus",
            render: (leaseStatus: string) => (
                <Tag color={leaseStatus === "Active" ? "green" : "red"}>{leaseStatus}</Tag>
            ),
        },
    ];

    const overdueServiceCount: number = 5;
    const recentlyCreatedServiceCount: number = 6;
    const recentlyCompletedServiceCount: number = 1;

    return (
        <div className="container">
            <h1 className="mb-4">Work-Orders & Complaints</h1>

            {/* Alerts headers */}
            <div className="d-flex w-100 justify-content-between">
                {
                    overdueServiceCount > 0 ?
                        <AlertComponent
                            description={`${overdueServiceCount} overdue services`}
                        /> : null
                }
                {
                    recentlyCreatedServiceCount > 0 ?
                        <AlertComponent
                            description={`${recentlyCreatedServiceCount} services created in past 48 hours`}
                        /> : null
                }
                {
                    recentlyCompletedServiceCount > 0 ?
                        <AlertComponent
                            description={`${recentlyCompletedServiceCount} services completed in past 24 hours`}
                        /> : null
                }
            </div>
        </div>
    )
};

export default AdminWorkOrder;