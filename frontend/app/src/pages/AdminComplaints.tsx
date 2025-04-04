import "../styles/styles.scss";

import { Tag } from "antd";
import dayjs from "dayjs";
import { Input, Select } from "antd";
import { SearchOutlined } from "@ant-design/icons";
import ModalComponent from "../components/ModalComponent";
import TableComponent from "../components/reusableComponents/TableComponent";
import type { ColumnsType, ColumnType } from "antd/es/table/interface";
import { WorkOrderData, ComplaintsData } from "../types/types";
import type { TablePaginationConfig } from "antd";
import { useState } from "react";
import PageTitleComponent from "../components/reusableComponents/PageTitleComponent";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "@clerk/clerk-react";

const serverUrl = import.meta.env.VITE_SERVER_URL;
const absoluteServerUrl = `${serverUrl}`;

export default function AdminComplaints() {
    const [selectedItem, setSelectedItem] = useState<WorkOrderData | ComplaintsData | null>(null);
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [itemType, setItemType] = useState<"workOrder" | "complaint">("workOrder");
    const [currentStatus, setCurrentStatus] = useState<string>("");

    const { getToken } = useAuth();
    const queryClient = useQueryClient();
    const { data: complaintsData, isLoading: isComplaintsLoading } = useQuery({
        queryKey: ["complaints"],
        queryFn: async () => {
            const token = await getToken();
            const response = await fetch(`${absoluteServerUrl}/admin/complaints`, {
                method: "GET",
                headers: {
                    Authorization: `Bearer ${token}`,
                    "Content-Type": "application/json",
                },
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            const data = (await response.json()) as ComplaintsData[];
            if (!Array.isArray(data)) {
                throw new Error("No complaints");
            }

            return data;
        },
    });

    const handleStatusChange = (newStatus: string) => {
        setCurrentStatus(newStatus);
    };
    const handleConfirm = async () => {
        if (selectedItem && currentStatus) {
            try {
                const token = await getToken();

                if (itemType === "workOrder") {
                    // Work order update logic (existing)
                    const response = await fetch(`${absoluteServerUrl}/admin/work_orders/${selectedItem.id}/status`, {
                        method: "PATCH",
                        headers: {
                            "Content-Type": "application/json",
                            Authorization: `Bearer ${token}`,
                        },
                        body: JSON.stringify({
                            status: currentStatus,
                        }),
                    });

                    if (!response.ok) {
                        throw new Error("Failed to update work order");
                    }

                    queryClient.setQueryData(["workOrders"], (oldData: WorkOrderData[] | undefined) => {
                        if (!oldData) return oldData;
                        return oldData.map((item) => (item.id === selectedItem.id ? { ...item, status: currentStatus, updatedAt: new Date() } : item));
                    });
                } else {
                    const response = await fetch(`${absoluteServerUrl}/admin/complaints/${selectedItem.id}/status`, {
                        method: "PATCH",
                        headers: {
                            "Content-Type": "application/json",
                            Authorization: `Bearer ${token}`,
                        },
                        body: JSON.stringify({
                            status: currentStatus,
                        }),
                    });

                    if (!response.ok) {
                        throw new Error("Failed to update complaint");
                    }

                    queryClient.setQueryData(["complaints"], (oldData: ComplaintsData[] | undefined) => {
                        if (!oldData) return oldData;
                        return oldData.map((item) => (item.id === selectedItem.id ? { ...item, status: currentStatus, updatedAt: new Date() } : item));
                    });
                }
                setIsModalVisible(false);
            } catch (error) {
                console.error("Error updating status:", error);
            }
        }
    };

    const handleRowClick = (record: WorkOrderData | ComplaintsData, type: "workOrder" | "complaint") => {
        setSelectedItem(record);
        setItemType(type);
        setCurrentStatus(record.status);
        setIsModalVisible(true);
    };

    const getComplaintColumnSearchProps = (dataIndex: keyof ComplaintsData, title: string): ColumnType<ComplaintsData> => ({
        filterDropdown: (filterDropdownProps) => (
            <div style={{ padding: 8 }}>
                <Input
                    placeholder={`Search ${title}`}
                    value={filterDropdownProps.selectedKeys[0]}
                    onChange={(e) => filterDropdownProps.setSelectedKeys(e.target.value ? [e.target.value] : [])}
                    onPressEnter={() => filterDropdownProps.confirm()}
                />
            </div>
        ),
        filterIcon: (filtered) => <SearchOutlined style={{ color: filtered ? "#1890ff" : undefined }} />,
        onFilter: (value, record) => {
            const val = record[dataIndex];
            return (
                val
                    ?.toString()
                    .toLowerCase()
                    .includes((value as string).toLowerCase()) ?? false
            );
        },
    });

    const shortenInput = (input: string, maxLength: number = 30) => {
        if (input.length > maxLength) {
            return input.substring(0, maxLength - 3) + "...";
        } else {
            return input;
        }
    };
    const complaintsColumns: ColumnsType<ComplaintsData> = [
        {
            title: "Complaint ID",
            dataIndex: "id",
            key: "id",
            ...getComplaintColumnSearchProps("id", "Complaint ID"),
            sorter: (a, b) => a.id - b.id,
        },
        {
            title: "Category",
            dataIndex: "category",
            key: "category",
            sorter: (a, b) => a.category.localeCompare(b.category),
            filters: [
                { text: "Maintenance", value: "maintenance" },
                { text: "Noise", value: "noise" },
                { text: "Security", value: "security" },
                { text: "Parking", value: "parking" },
                { text: "Neighbor", value: "neighbor" },
                { text: "Trash", value: "trash" },
                { text: "Internet", value: "internet" },
                { text: "Lease", value: "lease" },
                { text: "Natural Disaster", value: "natural_disaster" },
                { text: "Other", value: "other" },
            ],
            onFilter: (value, record) => record.category === (value as ComplaintsData["category"]),
            render: (category) => {
                let color = "";
                let text = "";

                switch (category) {
                    case "maintenance":
                        text = "Maintenance 🔧";
                        color = "blue";
                        break;
                    case "noise":
                        text = "Noise 🔊";
                        color = "orange";
                        break;
                    case "security":
                        text = "Security 🔒";
                        color = "red";
                        break;
                    case "parking":
                        text = "Parking 🚗";
                        color = "purple";
                        break;
                    case "neighbor":
                        text = "Neighbor 🏘️";
                        color = "green";
                        break;
                    case "trash":
                        text = "Trash 🗑️";
                        color = "brown";
                        break;
                    case "internet":
                        text = "Internet 🌐";
                        color = "cyan";
                        break;
                    case "lease":
                        text = "Lease 📝";
                        color = "gold";
                        break;
                    case "natural_disaster":
                        text = "Disaster 🌪️";
                        color = "grey";
                        break;
                    default:
                        text = "Other";
                        color = "default";
                }

                return <Tag color={color}>{text}</Tag>;
            },
            className: "text-center",
        },
        {
            title: "Title",
            dataIndex: "title",
            key: "title",
            ...getComplaintColumnSearchProps("title", "Title"),
            render: (title: string) => shortenInput(title, 25),
        },
        {
            title: "Description",
            dataIndex: "description",
            key: "description",
            ...getComplaintColumnSearchProps("description", "Description"),
            render: (description: string) => shortenInput(description),
        },
        {
            title: "Unit",
            dataIndex: "unitNumber",
            key: "unitNumber",
            ...getComplaintColumnSearchProps("unitNumber", "Unit"),
        },
        {
            title: "Status",
            dataIndex: "status",
            key: "status",
            ...getComplaintColumnSearchProps("status", "Status"),
            render: (status: string) => {
                let color = "default";
                switch (status) {
                    case "in_progress":
                        color = "blue";
                        break;
                    case "resolved":
                        color = "green";
                        break;
                    case "closed":
                        color = "gray";
                        break;
                    case "open":
                        color = "red";
                        break;
                }
                return <Tag color={color}>{status.replace("_", " ").toUpperCase()}</Tag>;
            },
            className: "text-center",
        },
        {
            title: "Created",
            dataIndex: "createdAt",
            key: "createdAt",
            sorter: (a, b) => dayjs(a.createdAt).unix() - dayjs(b.createdAt).unix(),
            render: (date) => dayjs(date).format("MMM D, YYYY h:mm A"),
        },
        {
            title: "Updated",
            dataIndex: "updatedAt",
            key: "updatedAt",
            sorter: (a, b) => dayjs(a.updatedAt).unix() - dayjs(b.updatedAt).unix(),
            render: (date) => dayjs(date).format("MMM D, YYYY h:mm A"),
        },
    ];

    const paginationConfig: TablePaginationConfig = {
        pageSize: 5,
        showSizeChanger: false,
    };
    const modalContent = selectedItem && (
        <div>
            <div className="mb-4">
                <strong>Title:</strong> {selectedItem.title}
            </div>
            <div className="mb-4">
                <strong>Description:</strong> {selectedItem.description}
            </div>
            <div className="mb-4">
                <strong>Unit Number:</strong> {selectedItem.unitNumber}
            </div>
            <div>
                <strong>Status:</strong>
                <Select
                    value={currentStatus}
                    style={{ width: 200, marginLeft: 10 }}
                    onChange={handleStatusChange}>
                    {itemType === "workOrder" ? (
                        <>
                            <Select.Option value="open">Open</Select.Option>
                            <Select.Option value="in_progress">In Progress</Select.Option>
                            <Select.Option value="resolved">Resolved</Select.Option>
                            <Select.Option value="closed">Closed</Select.Option>
                        </>
                    ) : (
                        <>
                            <Select.Option value="open">Open</Select.Option>
                            <Select.Option value="in_progress">In Progress</Select.Option>
                            <Select.Option value="resolved">Resolved</Select.Option>
                            <Select.Option value="closed">Closed</Select.Option>
                        </>
                    )}
                </Select>
            </div>
        </div>
    );
    return (
        <div className="container">
            <PageTitleComponent title="Complaints" />
            <div className="mb-5">
                <TableComponent<ComplaintsData>
                    columns={complaintsColumns}
                    dataSource={complaintsData}
                    style=".lease-table-container"
                    loading={isComplaintsLoading}
                    pagination={paginationConfig}
                    onChange={(pagination, filters, sorter, extra) => {
                        console.log("Table changed:", pagination, filters, sorter, extra);
                    }}
                    onRow={(record: ComplaintsData) => ({
                        onClick: () => handleRowClick(record, "complaint"),
                        style: {
                            cursor: "pointer",
                        },
                        className: "hoverable-row",
                    })}
                />
            </div>

            {selectedItem && (
                <ModalComponent
                    buttonTitle=""
                    buttonType="default"
                    content={modalContent}
                    type="default"
                    handleOkay={handleConfirm}
                    modalTitle={`${itemType === "workOrder" ? "Work Order" : "Complaint"} Details`}
                    isModalOpen={isModalVisible}
                    onCancel={() => setIsModalVisible(false)}
                    apartmentBuildingSetEditBuildingState={() => {}}
                />
            )}
        </div>
    );
}
