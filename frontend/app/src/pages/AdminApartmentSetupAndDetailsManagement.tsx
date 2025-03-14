import { Button, Form, Input, Select, Table } from "antd";
import React from "react";
import TableComponent from "../components/reusableComponents/TableComponent";
import ButtonComponent from "../components/reusableComponents/ButtonComponent";
import { DeleteOutlined, PlusOutlined } from "@ant-design/icons";

// Make the Add Locations a Modal that adds a building, floor, and room number
// The user can add multiple locations

const AdminApartmentSetupAndDetailsManagement = () => {
    const [isModalOpen, setIsModalOpen] = React.useState(false);

    // State that holds the locations (building #, floor #s in that building, room numbers in that building) that the user has added
    const [locations, setLocations] = React.useState<{ building: number; floors: number[]; rooms: number[] }[]>([]);

    const columns = [
        {
            title: "Building",
            dataIndex: "building",
            key: "building",
        },
        {
            title: "Floors",
            dataIndex: "floors",
            key: "floors",
            render: (floors: number[]) => floors.join(", "),
        },
        {
            title: "Rooms",
            dataIndex: "rooms",
            key: "rooms",
            render: (rooms: number[]) => rooms.join(", "),
        },
        {
            title: "Action",
            key: "action",
            render: (text: string, record: { building: number; floors: number[]; rooms: number[] }) => (
                <div className="flex gap-2">
                    <ButtonComponent
                        title="Delete"
                        type="danger"
                        icon={<DeleteOutlined />}
                        onClick={() => {
                            setLocations(locations.filter((location) => location.building !== record.building));
                        }}
                    />
                    <ButtonComponent
                        title="Edit"
                        type="primary"
                        onClick={() => {
                            console.log("Edit Location", record);
                        }}
                    />
                </div>
            ),
        },
    ];

    return (
        <div className="container">
            <h1 className="mb-3">Admin Apartment Setup And Details Management</h1>
            {/* Form to set up the apartment or edit the setup */}
            {/* I need these sections */}
            {/* Location (Floor 1, Floor 2, Floor 3) */}
            {/* Room Numbers ( 0-999) */}
            {/* Parking Settings (Available Spots, and Max Spots Per User */}
            {/* Mail Locker Settings (Available Lockers)*/}
            {/* SMTP Settings (Url/Domain, Port, Username, Password) */}
            {/* Apartment Manager Contact Information (Phone Number, Email) */}
            {/* Cancel and Submit Buttons */}
            <Form
                className="admin-apartment-setup-form-container"
                layout="vertical">
                {/* Table */}
                {locations.length > 0 && (
                    <TableComponent
                        dataSource={locations}
                        columns={columns}
                    />
                )}
                {/* Add Location */}
                <Form.Item
                    name="location"
                    label="Add Location"
                    rules={[
                        {
                            required: true,
                            message: "Please select a location",
                        },
                    ]}>
                    <div className="flex flex-row gap-3 mt-3">
                        <Input placeholder="Building #" />
                        <Input placeholder="# of Floors" />
                        <Input placeholder="# of Room" />
                    </div>
                </Form.Item>
                {/* Clear Button */}
                <div className="flex gap-2 mb-3">
                    <ButtonComponent
                        title="Clear Locations"
                        type="danger"
                        className="flex mb-3"
                        icon={<DeleteOutlined />}
                        onClick={() => {
                            setLocations([]);
                        }}>
                        Clear Locations
                    </ButtonComponent>
                    {/* Add Location Button */}
                    <Button
                        type="primary"
                        className="flex mb-3"
                        icon={<PlusOutlined />}
                        onClick={() => {
                            const buildingInput = document.querySelector('input[placeholder="Building #"]') as HTMLInputElement;
                            const building = parseInt(buildingInput?.value || "0");
                            const floors = document.querySelector('input[placeholder="# of Floors"]') as HTMLInputElement;
                            const rooms = document.querySelector('input[placeholder="# of Room"]') as HTMLInputElement;
                            setLocations([...locations, { building, floors: [parseInt(floors?.value || "0")], rooms: [parseInt(rooms?.value || "0")] }]);
                        }}>
                        Add Location
                    </Button>
                </div>
                {/* <TableComponent /> */}
                {/* <Form.Item
                    name="room-numbers"
                    label="Room Numbers"
                    rules={[{ required: true, message: "Please enter room numbers" }]}>
                    <Select placeholder="Room Numbers">
                        {[...Array(101)].map((_, i) => (
                            <Select.Option
                                key={i}
                                value={i}>
                                {i}
                            </Select.Option>
                        ))}
                    </Select>
                </Form.Item> */}
                <Form.Item
                    name="parking-settings"
                    label="Parking Settings"
                    rules={[{ required: true, message: "Please enter parking settings" }]}>
                    {/* Available Spots */}
                    <div className="flex flex-column gap-3">
                        <Input placeholder="Available Spots" />
                        {/* Max Spots Per User */}
                        <Input placeholder="Max Spots Per User" />
                    </div>
                </Form.Item>
                <Form.Item
                    name="mail-locker-settings"
                    label="Mail Locker Settings"
                    rules={[{ required: true, message: "Please enter mail locker settings" }]}>
                    <Input placeholder="Available Lockers" />
                </Form.Item>
                <Form.Item
                    name="smtp-settings"
                    label="SMTP Settings"
                    rules={[{ required: true, message: "Please enter SMTP settings" }]}>
                    <div className="flex flex-column gap-3">
                        {/* Url / Domain */}
                        <Input placeholder="Url/Domain" />
                        {/* Port */}
                        <Input placeholder="Port" />
                        {/* Username */}
                        <Input placeholder="Username" />
                        {/* Password */}
                        <Input placeholder="Password" />
                    </div>
                </Form.Item>
                <Form.Item
                    name="apartment-manager-contact-information"
                    label="Apartment Manager Contact Information"
                    rules={[
                        {
                            required: true,
                            message: "Please enter apartment manager contact information",
                        },
                    ]}>
                    <div className="flex flex-column gap-3">
                        {/* Phone Number */}
                        <Input placeholder="Phone Number" />
                        {/* Email */}
                        <Input placeholder="Email" />
                    </div>
                </Form.Item>
                <div className="flex justify-content-end gap-2">
                    {/* Cancel button */}
                    <Form.Item name="cancel">
                        <Button
                            type="default"
                            onClick={() => {
                                setIsModalOpen(false);
                            }}>
                            Cancel
                        </Button>
                    </Form.Item>
                    {/* Submit Button */}
                    <Form.Item name="submit">
                        <Button
                            type="primary"
                            htmlType="submit">
                            Submit
                        </Button>
                    </Form.Item>
                </div>
            </Form>
        </div>
    );
};

export default AdminApartmentSetupAndDetailsManagement;
