import "../styles/styles.scss";

import { Tag } from "antd";
import ModalComponent from "../components/ModalComponent";
import TableComponent from "../components/reusableComponents/TableComponent";
import ButtonComponent from "../components/reusableComponents/ButtonComponent";
import type { ColumnsType } from "antd/es/table/interface";

const AdminWorkOrder = () => {
    const handleAddPackage = () => {
        console.log("Added package successfully.")
    };

    const columnsLeases: ColumnsType<{ name: string; roomNumber: string; leaseStatus: string }> = [
        { title: "Name", dataIndex: "name" },
        { title: "Room Number", dataIndex: "roomNumber" },
        {
            title: "Lease Status",
            dataIndex: "leaseStatus",
            render: (leaseStatus: string) => (
                <Tag color={leaseStatus === "Active" ? "green" : "red"}>{leaseStatus}</Tag>
            ),
        },
    ];
}

export default AdminWorkOrder;