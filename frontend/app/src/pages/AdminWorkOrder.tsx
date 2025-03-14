import "../styles/styles.scss";

import dayjs from "dayjs";
import { Tag } from "antd";
import { Input, Space } from "antd";
import { SearchOutlined } from "@ant-design/icons";
import ModalComponent from "../components/ModalComponent";
import TableComponent from "../components/reusableComponents/TableComponent";
import ButtonComponent from "../components/reusableComponents/ButtonComponent";
import type { ColumnsType, ColumnType } from "antd/es/table/interface";
import AlertComponent from "../components/reusableComponents/AlertComponent";
import { WorkOrderData } from "../types/types";
import type { TableProps, TablePaginationConfig } from "antd";


const today = dayjs();

// This is the dropdown that performs a search in each column
const getColumnSearchProps = (dataIndex: keyof WorkOrderData, title: string): ColumnType<WorkOrderData> => {
    return {
        filterDropdown: (filterDropdownProps) => {
            return (
                <div style={{ padding: 8 }}>
                    <Input
                        placeholder={"Search " + title}
                        value={filterDropdownProps.selectedKeys[0]}
                        onChange={(e) => filterDropdownProps.setSelectedKeys(e.target.value ? [e.target.value] : [])}
                    />
                    <ButtonComponent
                        type="primary"
                        title="Search"
                        icon={<SearchOutlined />}
                        size="small"
                        onClick={() => filterDropdownProps.confirm()}
                    />
                    <ButtonComponent
                        type="default"
                        title="Reset"
                        size="small"
                        onClick={() => {
                            filterDropdownProps.clearFilters && filterDropdownProps.clearFilters();
                            filterDropdownProps.confirm();
                        }}
                    />
                </div>
            );
        },
        filterIcon: function (filtered) {
            return <SearchOutlined style={{ color: filtered ? "#1677ff" : undefined }} />;
        },
        onFilter: function (value, record) {
            return record[dataIndex].toString().toLowerCase().includes(value.toString().toLowerCase());
        },
    };
};


// DUMMY DATA THIS WILL BE DELETED :D
const workOrderDataRaw: WorkOrderData[] = [
    {
        key: 1,
        workOrderNumber: 10001,
        creatingBy: 3,
        category: "plumbing",
        title: "Leaking Kitchen Sink",
        description: "Water is slowly leaking from under the kitchen sink and forming a puddle on the floor.",
        apartmentNumber: "C466",
        status: "open",
        createdAt: new Date("2025-02-15T09:30:00"),
        updatedAt: new Date("2025-02-15T09:30:00")
    },
    {
        key: 2,
        workOrderNumber: 10002,
        creatingBy: 1,
        category: "electrical",
        title: "Bathroom Light Flickering",
        description: "The bathroom light has been flickering for two days and sometimes goes out completely.",
        apartmentNumber: "B218",
        status: "in progress",
        createdAt: new Date("2025-02-10T14:45:00"),
        updatedAt: new Date("2025-02-12T11:20:00")
    },
    {
        key: 3,
        workOrderNumber: 10003,
        creatingBy: 10,
        category: "hvac",
        title: "AC Not Cooling",
        description: "Air conditioner is running but not cooling the apartment. Temperature is getting uncomfortable.",
        apartmentNumber: "A101",
        status: "awaiting parts",
        createdAt: new Date("2025-01-30T16:20:00"),
        updatedAt: new Date("2025-02-02T09:15:00")
    },
    {
        key: 4,
        workOrderNumber: 10004,
        creatingBy: 5,
        category: "carpentry",
        title: "Broken Cabinet Door",
        description: "Kitchen cabinet door hinge is broken and the door won't stay closed.",
        apartmentNumber: "C378",
        status: "completed",
        createdAt: new Date("2025-02-05T10:00:00"),
        updatedAt: new Date("2025-02-08T15:30:00")
    },
    {
        key: 5,
        workOrderNumber: 10005,
        creatingBy: 8,
        category: "plumbing",
        title: "Clogged Toilet",
        description: "Toilet is clogged and won't flush properly. Plunger hasn't helped.",
        apartmentNumber: "C299",
        status: "open",
        createdAt: new Date("2025-02-18T08:10:00"),
        updatedAt: new Date("2025-02-18T08:10:00")
    },
    {
        key: 6,
        workOrderNumber: 10006,
        creatingBy: 2,
        category: "electrical",
        title: "No Power in Bedroom",
        description: "Electrical outlets in the bedroom aren't working. Breaker hasn't tripped.",
        apartmentNumber: "A212",
        status: "in progress",
        createdAt: new Date("2025-02-14T12:30:00"),
        updatedAt: new Date("2025-02-14T16:45:00")
    },
    {
        key: 7,
        workOrderNumber: 10007,
        creatingBy: 4,
        category: "other",
        title: "Stuck Window",
        description: "Living room window is stuck and won't open. Frame seems to be warped.",
        apartmentNumber: "B179",
        status: "open",
        createdAt: new Date("2025-02-17T11:25:00"),
        updatedAt: new Date("2025-02-17T11:25:00")
    },
    {
        key: 8,
        workOrderNumber: 10008,
        creatingBy: 6,
        category: "hvac",
        title: "Noisy Heater",
        description: "Heating system is making loud banging noises when it starts up.",
        apartmentNumber: "A333",
        status: "awaiting parts",
        createdAt: new Date("2025-01-25T09:50:00"),
        updatedAt: new Date("2025-01-29T14:20:00")
    },
    {
        key: 9,
        workOrderNumber: 10009,
        creatingBy: 9,
        category: "plumbing",
        title: "Low Water Pressure",
        description: "Water pressure in the shower is very low. All other faucets seem normal.",
        apartmentNumber: "B155",
        status: "completed",
        createdAt: new Date("2025-01-20T13:15:00"),
        updatedAt: new Date("2025-01-23T10:40:00")
    },
    {
        key: 10,
        workOrderNumber: 10010,
        creatingBy: 7,
        category: "carpentry",
        title: "Damaged Baseboards",
        description: "Baseboards in the living room are damaged and coming away from the wall in several places.",
        apartmentNumber: "D401",
        status: "in progress",
        createdAt: new Date("2025-02-12T15:00:00"),
        updatedAt: new Date("2025-02-13T11:30:00")
    }
];

const workOrderColumns: ColumnsType<WorkOrderData> = [
    {
        title: "Apartment No.",
        dataIndex: "apartmentNumber",
        key: "apartmentNumber",
        sorter: (a, b) => a.apartmentNumber.localeCompare(b.apartmentNumber),
        ...getColumnSearchProps("apartmentNumber", "Apartment No."),
        className: "text-secondary text-left",
    },
    {
        title: "Category",
        dataIndex: "category",
        key: "category",
        sorter: (a, b) => a.category.localeCompare(b.category),
        ...getColumnSearchProps("category", "Category"),
    },
    {
        title: "Inquiry",
        dataIndex: "title",
        key: "title",
        sorter: (a, b) => a.title.localeCompare(b.title),
        ...getColumnSearchProps("title", "Inquiry"),
    },
    {
        title: "Description",
        dataIndex: "description",
        key: "description",
        ...getColumnSearchProps("description", "Description"),
    },
    {
        title: "Created",
        dataIndex: "createdAt",
        key: "createdAt",
        ...getColumnSearchProps("createdAt", "Created"),
        sorter: (a, b) => dayjs(a.createdAt).unix() - dayjs(b.createdAt).unix(),
        render: (date) => dayjs(date).format("MMM D, YYYY h:mm A"),
    },
    {
        title: "Updated",
        dataIndex: "updatedAt",
        key: "updatedAt",
        ...getColumnSearchProps("createdAt", "Updated"),
        sorter: (a, b) => dayjs(a.updatedAt).unix() - dayjs(b.updatedAt).unix(),
        render: (date) => dayjs(date).format("MMM D, YYYY h:mm A"),
    },
    {
        title: "Status",
        dataIndex: "status",
        key: "status",
        filters: [
            { text: "Open", value: "open" },
            { text: "In Progress", value: "in progress" },
            { text: "Awaiting Parts", value: "awaiting parts" },
            { text: "Completed", value: "completed" },
        ],
        onFilter: (value, record) => record.status === value,
        render: (status) => {
            let color = "";
            let text = "";

            switch (status) {
                case "open":
                    color = "red";
                    text = "Open";
                    break;
                case "in progress":
                    color = "blue";
                    text = "In Progress";
                    break;
                case "awaiting parts":
                    color = "orange";
                    text = "Awaiting Parts";
                    break;
                case "completed":
                    color = "green";
                    text = "Completed";
                    break;
                default:
                    color = "default";
                    text = status;
            }

            return <Tag color={color}>{text}</Tag>;
        },
        sorter: (a, b) => a.status.localeCompare(b.status),
        className: "text-center",
    },
];

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
            <div className="d-flex w-100 justify-content-between mb-4">
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

            {/* Work Order Table */}
            <TableComponent<WorkOrderData>
                columns={workOrderColumns}
                dataSource={workOrderDataRaw}
                style=".lease-table-container"
                onChange={(
                    pagination: TablePaginationConfig,
                    filters: Parameters<NonNullable<TableProps<WorkOrderData>["onChange"]>>[1],
                    sorter: Parameters<NonNullable<TableProps<WorkOrderData>["onChange"]>>[2],
                    extra: Parameters<NonNullable<TableProps<WorkOrderData>["onChange"]>>[3],
                ) => {
                    console.log("Table changed:", pagination, filters, sorter, extra);
                }}
            />

            {/* Complaints Table */}
            <TableComponent<WorkOrderData>
                columns={workOrderColumns}
                dataSource={workOrderDataRaw}
                style=".lease-table-container"
                onChange={(
                    pagination: TablePaginationConfig,
                    filters: Parameters<NonNullable<TableProps<WorkOrderData>["onChange"]>>[1],
                    sorter: Parameters<NonNullable<TableProps<WorkOrderData>["onChange"]>>[2],
                    extra: Parameters<NonNullable<TableProps<WorkOrderData>["onChange"]>>[3],
                ) => {
                    console.log("Table changed:", pagination, filters, sorter, extra);
                }}
            />
        </div>
    )
};

export default AdminWorkOrder;