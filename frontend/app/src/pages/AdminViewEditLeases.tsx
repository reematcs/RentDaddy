import "../styles/styles.scss"
import React, { useState } from "react";
import { SearchOutlined } from "@ant-design/icons";
import { Input, Table, Tag, Space, Tree } from "antd";
import type { ColumnsType } from "antd/es/table";

const { Search } = Input
import dayjs from "dayjs";
import { LeaseData } from "../types/types";
import TableComponent from "../components/TableComponent";
import ButtonComponent from "../components/reusableComponents/ButtonComponent";

// Dummy lease data
const leaseDataRaw = [
    { key: 1, tenantName: "Grace Hall", apartment: "B218", leaseStartDate: "2024-06-13", leaseEndDate: "2024-12-10", rentAmount: 2060, status: "draft" }, // Draft
    { key: 2, tenantName: "James Smith", apartment: "A212", leaseStartDate: "2024-03-20", leaseEndDate: "2024-09-01", rentAmount: 2223, status: "pending_approval" }, // Pending Approval
    { key: 3, tenantName: "Diego Lewis", apartment: "C466", leaseStartDate: "2024-05-01", leaseEndDate: "2025-04-12", rentAmount: 1100, status: "active" }, // Active
    { key: 4, tenantName: "Hector Wilson", apartment: "B179", leaseStartDate: "2024-10-02", leaseEndDate: "2025-03-31", rentAmount: 2150, status: "active" }, // Active
    { key: 5, tenantName: "Charlie Davis", apartment: "C378", leaseStartDate: "2024-11-03", leaseEndDate: "2025-11-03", rentAmount: 1803, status: "active" }, // Active
    { key: 6, tenantName: "JJ SchraderBachar", apartment: "A333", leaseStartDate: "2024-07-15", leaseEndDate: "2024-08-30", rentAmount: 1950, status: "expires_soon" }, // Expires Soon
    { key: 7, tenantName: "Rosalind Franklin", apartment: "D401", leaseStartDate: "2023-02-10", leaseEndDate: "2024-02-10", rentAmount: 1200, status: "expired" }, // Expired
    { key: 8, tenantName: "Malik Johnson", apartment: "C299", leaseStartDate: "2024-07-01", leaseEndDate: "2024-10-01", rentAmount: 1400, status: "expires_soon" }, // Expires Soon
    { key: 9, tenantName: "Carree Brown", apartment: "B155", leaseStartDate: "2024-05-01", leaseEndDate: "2024-07-01", rentAmount: 1750, status: "terminated" }, // Terminated
    { key: 10, tenantName: "John Doe", apartment: "A101", leaseStartDate: "2024-04-20", leaseEndDate: "2024-10-20", rentAmount: 2000, status: "active" }, // Active
    { key: 11, tenantName: "Jane Smith", apartment: "B221", leaseStartDate: "2024-06-25", leaseEndDate: "2024-07-25", rentAmount: 2100, status: "expired" }, // Expired
    { key: 12, tenantName: "Jill Hall", apartment: "D450", leaseStartDate: "2024-01-10", leaseEndDate: "2024-02-10", rentAmount: 1300, status: "terminated" }, // Terminated
    { key: 13, tenantName: "Emily Wildaughter", apartment: "C310", leaseStartDate: "2024-09-10", leaseEndDate: "2025-09-10", rentAmount: 1900, status: "active" }, // Active
    { key: 14, tenantName: "Charlie Chill", apartment: "A450", leaseStartDate: "2024-03-01", leaseEndDate: "2024-03-30", rentAmount: 1600, status: "expired" }, // Expired
    { key: 15, tenantName: "Planter Lewis", apartment: "D180", leaseStartDate: "2024-12-01", leaseEndDate: "2025-06-01", rentAmount: 1700, status: "active" }, // Active
    { key: 16, tenantName: "Unfrank Thomas", apartment: "B222", leaseStartDate: "2024-10-10", leaseEndDate: "2024-11-10", rentAmount: 2200, status: "expires_soon" }, // Expires Soon
    { key: 17, tenantName: "Henry Clark", apartment: "C199", leaseStartDate: "2024-07-15", leaseEndDate: "2024-09-15", rentAmount: 1450, status: "pending_approval" }, // Pending Approval
    { key: 18, tenantName: "Danny Thompson", apartment: "A205", leaseStartDate: "2024-11-05", leaseEndDate: "2025-05-05", rentAmount: 1800, status: "active" }, // Active
    { key: 19, tenantName: "Dennis Garcia", apartment: "D299", leaseStartDate: "2024-08-20", leaseEndDate: "2024-09-20", rentAmount: 1550, status: "expires_soon" }, // Expires Soon
    { key: 20, tenantName: "Yoon Soon", apartment: "B305", leaseStartDate: "2024-09-15", leaseEndDate: "2025-09-15", rentAmount: 2000, status: "active" }, // Active
];

const groupByDateHierarchy = (dates: string[], type: "startDate" | "endDate") => {
    const dateMap = new Map();

    dates.forEach((date) => {
        const parsedDate = dayjs(date);
        const year = parsedDate.format("YYYY");
        const month = parsedDate.format("MMMM"); // "January", "February", etc.
        const day = parsedDate.format("DD"); // "01", "02", etc.

        if (!dateMap.has(year)) dateMap.set(year, new Map());
        if (!dateMap.get(year).has(month)) dateMap.get(year).set(month, new Set());

        dateMap.get(year).get(month).add(day);
    });

    // Convert map structure to tree nodes
    return [...dateMap.entries()].map(([year, months]) => ({
        title: year,
        key: `${type}-${year}`, //"[startdate|enddate]-year"
        children: [...months.entries()].map(([month, days]) => ({
            title: month,
            key: `${type}-${year}-${month}`, //"[startdate|enddate]-year-month"
            children: [...days].map((day) => ({
                title: day,
                key: `${type}-${year}-${month}-${day}`,
            })),
        })),
    }));
};

const treeData = [
    {
        title: "Lease Status",
        key: "status",
        children: [
            { title: "Draft", key: "draft" },
            { title: "Pending Approval", key: "pending_approval" },
            { title: "Active", key: "active" },
            { title: "Expires Soon", key: "expiresSoon" },
            { title: "Terminated", key: "terminated" },
            { title: "Expired", key: "expired" },
        ],
    },
    {
        title: "Lease Start Dates",
        key: "leaseStartDates",
        children: groupByDateHierarchy(leaseDataRaw.map(lease => lease.leaseStartDate), "startDate"),
    },
    {
        title: "Lease End Dates",
        key: "leaseEndDates",
        children: groupByDateHierarchy(leaseDataRaw.map(lease => lease.leaseEndDate), "endDate"),
    },
];

const tableColumns: ColumnsType<LeaseData> = [
    {
        title: "Tenant Name",
        dataIndex: "tenantName",
        key: "tenantName",
    },
    {
        title: "Apartment",
        dataIndex: "apartment",
        key: "apartment",
    },
    {
        title: "Status",
        dataIndex: "status",
        key: "status",
        render: (_: unknown, record: LeaseData) => {
            const status = getLeaseStatus(record);
            const statusColors: Record<string, string> = {
                "Valid": "green",
                "Expires Soon": "orange",
                "Unsigned": "red",
                "Expired": "gray",
            };

            return <Tag color={statusColors[status]}>{status}</Tag>;
        },
    },
];

const getLeaseStatus = (record: LeaseData): "draft" | "pending_approval" | "active" | "expires_soon" | "terminated" | "expired" => {
    const today = dayjs();
    const leaseEnd = dayjs(record.leaseEndDate);
    const daysUntilExpiration = leaseEnd.diff(today, "days");

    if (record.status === "draft") return "draft";
    if (record.status === "pending_approval") return "pending_approval";
    if (record.status === "terminated") return "terminated";
    if (daysUntilExpiration < 0) return "expired";
    if (daysUntilExpiration <= 60) return "expires_soon";
    return "active";
};


const generateTreeData = (leaseData: LeaseData[]) => {
    const apartments = leaseData.map((lease) => lease.apartment);
    const tenants = leaseData.map((lease) => lease.tenantName);
    const statuses = ["draft", "pending_approval", "active", "expires_soon", "terminated", "expired"];

    const startDates = leaseData.map((lease) => lease.leaseStartDate);
    const endDates = leaseData.map((lease) => lease.leaseEndDate);

    return [
        {
            title: "Apartments",
            key: "apartments",
            children: apartments.map((apartment) => ({
                title: apartment,
                key: `apartment-${apartment}`,
            })),
        },
        {
            title: "Tenants",
            key: "tenants",
            children: tenants.map((tenant) => ({
                title: tenant,
                key: `tenant-${tenant}`,
            })),
        },
        {
            title: "Lease Status",
            key: "status",
            children: statuses.map((status) => ({
                title: status.replace("_", " "), // Make it more readable
                key: status,
            })),
        },
        {
            title: "Lease Start Dates",
            key: "leaseStartDates",
            children: groupByDateHierarchy(startDates, "startDate"),
        },
        {
            title: "Lease End Dates",
            key: "leaseEndDates",
            children: groupByDateHierarchy(endDates, "endDate"),
        },
    ];
};




export default function AdminViewEditLeases() {
    const [searchText, setSearchText] = useState("");
    const [selectedKeys, setSelectedKeys] = useState<string[]>([]);

    const treeData = generateTreeData(leaseDataRaw);

    const matchesSearchTerm = (record: LeaseData, searchTerm: string): boolean => {
        const lowerCaseSearch = searchTerm.toLowerCase();
        return (
            record.tenantName.toLowerCase().includes(lowerCaseSearch) ||
            record.apartment.toLowerCase().includes(lowerCaseSearch) ||
            record.leaseEndDate.includes(searchTerm) ||
            record.leaseStartDate.includes(searchTerm)
        );
    };

    const matchesTreeSelection = (record: LeaseData, selectedKeys: string[]): boolean => {
        if (selectedKeys.length === 0) return true; // No filters applied

        return selectedKeys.some((key) => {
            if (key.startsWith("apartment-")) return record.apartment === key.replace("apartment-", "");
            if (key.startsWith("tenant-")) return record.tenantName === key.replace("tenant-", "");

            const statusKeys = ["draft", "pending_approval", "active", "expires_soon", "terminated", "expired"];
            if (statusKeys.includes(key)) {
                return record.status === key;
            }

            const [type, year, month, day] = key.split("-");

            if (type === "startDate") {
                const leaseDate = dayjs(record.leaseStartDate);
                return (
                    (year && leaseDate.format("YYYY") === year) ||
                    (month && leaseDate.format("MMMM") === month) ||
                    (day && leaseDate.format("DD") === day)
                );
            }

            if (type === "endDate") {
                const leaseDate = dayjs(record.leaseEndDate);
                return (
                    (year && leaseDate.format("YYYY") === year) ||
                    (month && leaseDate.format("MMMM") === month) ||
                    (day && leaseDate.format("DD") === day)
                );
            }

            return false;
        });
    };





    const filteredData = leaseDataRaw.filter(
        (record) => matchesSearchTerm(record, searchText) && matchesTreeSelection(record, selectedKeys)
    );


    const leaseColumns: ColumnsType<LeaseData> = [
        {
            title: "Tenant Name",
            dataIndex: "tenantName",
            className: "text-primary",
            sorter: (a, b) => a.tenantName.localeCompare(b.tenantName),
        },
        { title: "Apartment", dataIndex: "apartment" },
        {
            title: "Lease Start",
            dataIndex: "leaseStartDate",
            sorter: (a, b) => dayjs(a.leaseStartDate).unix() - dayjs(b.leaseStartDate).unix(),
            render: (text) => {
                const isExpired = dayjs(text).isAfter(dayjs());
                return <span style={{ color: isExpired ? "gray" : "black" }}>{text}</span>;
            },
        },
        {
            title: "Lease End",
            dataIndex: "leaseEndDate",
            sorter: (a, b) => dayjs(a.leaseEndDate).unix() - dayjs(b.leaseEndDate).unix(),
            render: (text) => {
                const isExpired = dayjs(text).isBefore(dayjs());
                return <span style={{ color: isExpired ? "gray" : "black" }}>{text}</span>;
            },
        },
        {
            title: "Status",
            dataIndex: "status",
            key: "status",
            sorter: (a, b) => a.status.localeCompare(b.status), // Sorting stays the same
            render: (_: unknown, record: LeaseData) => {
                const statusColors: Record<string, string> = {
                    "draft": "blue",
                    "pending_approval": "purple",
                    "active": "green",
                    "expires_soon": "orange",
                    "terminated": "red",
                    "expired": "gray",
                };

                return <Tag color={statusColors[record.status] || "default"}>
                    {record.status.replace("_", " ")}
                </Tag>;
            },
        },
        {
            title: "Rent ($)", dataIndex: "rentAmount",
            sorter: (a, b) => a.rentAmount - b.rentAmount,
        },
        {
            title: "Actions",
            key: "actions",
            className: "fw-bold",
            render: (_, record) => {
                const status = getLeaseStatus(record);

                return (
                    <Space size="middle">
                        {status === "draft" && (
                            <ButtonComponent type="primary" title="Send Lease" onClick={() => console.log("Send Lease", record)} />
                        )}
                        {status === "active" && (
                            <ButtonComponent type="danger" title="Terminate" onClick={() => console.log("Terminate Lease", record)} />
                        )}
                        {status === "expires_soon" && (
                            <>
                                <ButtonComponent type="danger" title="Terminate" onClick={() => console.log("Terminate Lease", record)} />
                                <ButtonComponent type="primary" title="Send Renewal" onClick={() => console.log("Send Renewal", record)} />
                            </>
                        )}
                        {/* No buttons for "terminated", "expired", or "pending_approval" */}
                    </Space>
                );
            },
        },
    ];


    return (
        <div className="container" style={{ width: "100%" }}>
            <h1 className="mb-4 text-primary">Admin View & Edit Leases</h1>

            <div className="flex" style={{ gap: "20px" }}>

                <div style={{ width: "250px" }}>
                    <Search
                        placeholder="Search leases..."
                        allowClear
                        onChange={(e) => setSearchText(e.target.value)}
                        style={{ marginBottom: 16, width: "100%" }}
                    />
                    <Tree
                        treeData={treeData}
                        checkable
                        onCheck={(checkedKeys, info) => {
                            const keys = Array.isArray(checkedKeys) ? checkedKeys.map(String) : checkedKeys.checked.map(String);
                            setSelectedKeys(keys);
                        }}
                    />

                </div>
                <div style={{ flex: 1, width: "100%" }}>
                    <TableComponent columns={leaseColumns} dataSource={filteredData} />
                </div >
            </div >
        </div >
    );
}
