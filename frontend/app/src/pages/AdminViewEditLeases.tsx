import "../styles/styles.scss";
import { useState } from "react";
import { Input, Tag, Space, Tree } from "antd";
import type { ColumnsType } from "antd/es/table";
import dayjs from "dayjs";
import TableComponent from "../components/reusableComponents/TableComponent.tsx";
import ButtonComponent from "../components/reusableComponents/ButtonComponent";

const { Search } = Input;
const today = dayjs();

// Lease Data with Updated Rules
const leaseDataRaw = [
    { key: 1, tenantName: "Grace Hall", apartment: "B218", leaseStartDate: "2024-06-13", leaseEndDate: "2024-12-13", rentAmount: 2060, status: "draft" },
    { key: 2, tenantName: "James Smith", apartment: "A212", leaseStartDate: "2024-03-20", leaseEndDate: "2024-09-20", rentAmount: 2223, status: "pending_approval" },
    { key: 3, tenantName: "Diego Lewis", apartment: "C466", leaseStartDate: "2024-05-01", leaseEndDate: "2025-05-01", rentAmount: 1100, status: "active" },
    { key: 4, tenantName: "Hector Wilson", apartment: "B179", leaseStartDate: "2024-10-02", leaseEndDate: "2025-10-02", rentAmount: 2150, status: "active" },
    { key: 5, tenantName: "Rosalind Franklin", apartment: "D401", leaseStartDate: "2023-02-10", leaseEndDate: "2024-02-10", rentAmount: 1200, status: "expired" },
];



const getLeaseStatus = (record: { leaseEndDate: string; status: string }) => {
    const leaseEnd = dayjs(record.leaseEndDate);
    if (record.status === "draft" || record.status === "pending_approval") return record.status;
    if (record.status === "terminated") return "terminated";
    if (leaseEnd.isBefore(today)) return "expired";
    if (leaseEnd.diff(today, "days") <= 60) return "expires_soon";
    return "active";
};

export default function AdminViewEditLeases() {


    const filteredData = leaseDataRaw.map((lease) => ({
        ...lease,
        status: getLeaseStatus(lease),
    }));

    interface LeaseData {
        key: number;
        tenantName: string;
        apartment: string;
        leaseStartDate: string;
        leaseEndDate: string;
        rentAmount: number;
        status: string;
    }

    const leaseColumns: ColumnsType<LeaseData> = [
        { title: "Tenant Name", dataIndex: "tenantName", sorter: (a, b) => a.tenantName.localeCompare(b.tenantName) },
        { title: "Apartment", dataIndex: "apartment" },
        { title: "Lease Start", dataIndex: "leaseStartDate", sorter: (a, b) => dayjs(a.leaseStartDate).unix() - dayjs(b.leaseStartDate).unix() },
        { title: "Lease End", dataIndex: "leaseEndDate", sorter: (a, b) => dayjs(a.leaseEndDate).unix() - dayjs(b.leaseEndDate).unix() },
        {
            title: "Status", dataIndex: "status",
            render: (_, record) => <Tag>{record.status.replace("_", " ")}</Tag>
        },
        {
            title: "Actions", key: "actions",
            render: (_, record) => (
                <Space>
                    {record.status === "draft" && <ButtonComponent type="primary" title="Initiate Lease" />}
                    {record.status === "active" && <ButtonComponent type="danger" title="Terminate" />}
                    {record.status === "expires_soon" && (
                        <>
                            <ButtonComponent type="danger" title="Terminate" />
                            <ButtonComponent type="primary" title="Renew Lease" />
                        </>
                    )}
                </Space>
            )
        }
    ];

    return (
        <div className="container" style={{ width: "100%" }}>
            <h1 className="mb-4 text-primary">Admin View & Edit Leases</h1>

            <TableComponent<LeaseData> columns={leaseColumns} dataSource={filteredData} />
        </div>
    );
}
