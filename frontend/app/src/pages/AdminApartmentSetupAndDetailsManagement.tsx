import { Button, Form, Input } from "antd";
import React, { useState, useCallback } from "react";
import TableComponent from "../components/reusableComponents/TableComponent";
import ButtonComponent from "../components/reusableComponents/ButtonComponent";
import { DeleteOutlined, PlusOutlined } from "@ant-design/icons";
import ModalComponent from "../components/ModalComponent";
import { useMutation } from "@tanstack/react-query";
import PageTitleComponent from "../components/reusableComponents/PageTitleComponent";
import { useAuth } from "@clerk/clerk-react";

const API_URL = import.meta.env.VITE_BACKEND_URL;

// Make the Add Locations a Modal that adds a building, floor, and room number
// The user can add multiple locations

type Building = {
    buildingNumber: number;
    floorNumbers: number;
    numberOfRooms: number;
};

type AdminSetup = {
    parkingTotal: number;
    perUserParking: number;
    lockerCount: number;
    buildings: Building[];
    documensoApiKey?: string;
    documensoWebhookSecret?: string;
};

const AdminApartmentSetupAndDetailsManagement = () => {
    // State that holds the locations (building #, floor #s in that building, room numbers in that building)
    // TODO: When no longer needed for development, delete the clear locations button and mock data
    const [locations, setLocations] = React.useState<{ building: number; floors: number; rooms: number }[]>([]);
    const { getToken } = useAuth();
    const [tenantsExist, setTenantsExist] = useState(true);
    const [seedingStatus, setSeedingStatus] = useState<{
        user_seeding: { in_progress: boolean; last_error?: string; last_complete?: string };
        data_seeding: { in_progress: boolean; last_error?: string; last_complete?: string };
    } | null>(null);
    
    // Define seedStatus upfront to avoid the "used before declaration" error
    const {
        mutate: triggerSeedUsers,
        status: seedStatus
    } = useMutation({
        mutationFn: async () => {
            const token = await getToken();
            const res = await fetch(`${API_URL}/seed-users`, {
                method: "POST",
                headers: {
                    Authorization: `Bearer ${token}`,
                },
            });

            if (!res.ok) {
                const errText = await res.text();
                throw new Error(errText || "Failed to seed users");
            }

            return res;
        },
        onSuccess: async () => {
            console.log("✅ Seeding process started");
            
            // Immediately check status to get initial state
            try {
                const res = await fetch(`${API_URL}/seed-users/status`);
                if (res.ok) {
                    const data = await res.json();
                    setSeedingStatus(data);
                }
            } catch (error) {
                console.error("Failed to get initial seeding status", error);
            }
        },
        onError: (e: any) => {
            console.log("❌ Error seeding users:", e);
        },
    });
    
    const checkTenants = useCallback(async () => {
        try {
            const res = await fetch(`${API_URL}/check-admin`);
            const data = await res.json();
            setTenantsExist(data.tenants_exist);
        } catch (err) {
            console.error("Failed to check tenants", err);
        }
    }, [API_URL]);
    
    // Poll seeding status when needed
    React.useEffect(() => {
        let intervalId: number | undefined;
        let attempts = 0;
        const maxAttempts = 60; // 2 minutes max polling (60 * 2 sec)
        
        // Start polling in these cases:
        // 1. Initial seeding request was successful
        // 2. Seeding is in progress according to status
        const shouldPoll = 
            seedStatus === 'success' || 
            (seedingStatus && seedingStatus.user_seeding.in_progress);
            
        if (shouldPoll && (!seedingStatus || !seedingStatus.user_seeding.last_complete)) {
            intervalId = window.setInterval(async () => {
                attempts++;
                try {
                    // No authentication needed for status check
                    const res = await fetch(`${API_URL}/seed-users/status`);
                    if (res.ok) {
                        const data = await res.json();
                        setSeedingStatus(data);
                        
                        // If seeding is complete or we've reached max attempts
                        if (!data.user_seeding.in_progress || attempts >= maxAttempts) {
                            clearInterval(intervalId);
                            // Refresh tenant status
                            checkTenants();
                        }
                    }
                } catch (err) {
                    console.error("Failed to check seeding status", err);
                    if (attempts >= 5) { // Stop polling after 5 consecutive errors
                        clearInterval(intervalId);
                    }
                }
            }, 2000); // Poll every 2 seconds
        }
        
        return () => {
            if (intervalId) clearInterval(intervalId);
        };
    }, [seedStatus, seedingStatus, API_URL, checkTenants]);
    
    React.useEffect(() => {
        checkTenants();
    }, [checkTenants]);

    console.log("locations on load", locations);

    const [editBuildingObj, setEditBuildingObj] = useState<Building>({} as Building);

    const [adminSetupObject, setAdminSetupObject] = useState<AdminSetup>({
        parkingTotal: 0,
        perUserParking: 0,
        lockerCount: 0,
        buildings: [],
        documensoApiKey: '',
        documensoWebhookSecret: '',
    });

    console.log("adminSetupObject", adminSetupObject);

    console.log(editBuildingObj);

    const { mutate: adminApartmentSetup } = useMutation({
        mutationFn: async (adminSetupObject: AdminSetup) => {
            console.log("Starting admin apartment setup admin");
            const token = await getToken();

            console.log("adminSetupObject", adminSetupObject);

            const res = await fetch(`${API_URL}/admin/setup`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify(adminSetupObject),
            });

            console.log(res);

            if (!res.ok) {
                throw new Error("Failed to setup apartment");
            }

            return res;
        },
        onSuccess: () => {
            // Invalidate and refetch
            console.log("success");
        },
        onError: (e: any) => {
            console.log("error ", e);
        },
    });

    // console.log("Testing for Ryan, this is the adminApartmentSetup return from the Tanstack useMutation", adminApartmentSetup);

    const handleSendAdminSetup = () => {
        console.log("starting admin setup");
        adminApartmentSetup(adminSetupObject);

        // Reset the state
        setAdminSetupObject({
            parkingTotal: 0,
            perUserParking: 0,
            lockerCount: 0,
            buildings: [],
            documensoApiKey: '',
            documensoWebhookSecret: '',
        });

        console.log("adminSetupObject", adminSetupObject);
    };

    // tanstack for editing locations that were put in
    const { mutate: editLocations } = useMutation({
        mutationFn: async (buildingData: Building) => {
            console.log(editBuildingObj, "editBuildingObj in tanstack mutation");
            // TODO: James, when you finish the backend route, change the variable endpoint to the right one.
            const res = await fetch(`${API_URL}/admins/buildings/{id}`, {
                method: "PUT",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(buildingData),
            });

            if (!res.ok) {
                throw new Error("Failed to update location");
            }

            return res;
        },
        onSuccess: () => {
            // Invalidate and refetch
            console.log("success");
        },
        onError: (e: any) => {
            console.log("error ", e);
        },
    });

    const handleEditLocation = () => {
        console.log("starting edit location");
        editLocations(editBuildingObj);
    };

    const handleFormValuesChange = (_: any, allValues: any) => {
        setAdminSetupObject((prev) => ({
            ...prev,
            parkingTotal: Number(allValues["parking-settings"][0]) || 0,
            perUserParking: Number(allValues["parking-settings"][1]) || 0,
            lockerCount: Number(allValues["mail-locker-settings"]) || 0,
            documensoApiKey: allValues["documenso-settings"]?.apiKey || prev.documensoApiKey,
            documensoWebhookSecret: allValues["documenso-settings"]?.webhookSecret || prev.documensoWebhookSecret,
            buildings: prev.buildings,
        }));
    };

    // Handles adding the building to the locations state
    const handleAddLocation = () => {
        const buildingInput = document.querySelector('input[placeholder="Building #"]') as HTMLInputElement;
        const floorsInput = document.querySelector('input[placeholder="# of Floors"]') as HTMLInputElement;
        const roomsInput = document.querySelector('input[placeholder="# of Room"]') as HTMLInputElement;

        const newBuilding = {
            building: parseInt(buildingInput?.value || "0"),
            floors: parseInt(floorsInput?.value || "0"),
            rooms: parseInt(roomsInput?.value || "0"),
        };

        // Update locations state
        setLocations((prev) => [...prev, newBuilding]);

        // Update adminSetupObject with the new building
        setAdminSetupObject((prev) => ({
            ...prev,
            buildings: [
                ...prev.buildings,
                {
                    buildingNumber: newBuilding.building,
                    floorNumbers: newBuilding.floors,
                    numberOfRooms: newBuilding.rooms,
                },
            ],
        }));

        // Reset the inputs
        if (buildingInput) buildingInput.value = "";
        if (floorsInput) floorsInput.value = "";
        if (roomsInput) roomsInput.value = "";
    };

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
            render: (floors: number) => floors,
        },
        {
            title: "Rooms",
            dataIndex: "rooms",
            key: "rooms",
            render: (rooms: number) => rooms,
        },
        {
            title: "Action",
            key: "action",
            render: (_: any, record: { building: number; floors: number; rooms: number }) => (
                <div className="flex gap-2">
                    <ButtonComponent
                        title="Delete"
                        type="danger"
                        icon={<DeleteOutlined />}
                        onClick={() => {
                            setLocations(locations.filter((location) => location.building !== record.building));
                            setAdminSetupObject((prev) => ({
                                ...prev,
                                buildings: prev.buildings.filter((b) => b.buildingNumber !== record.building),
                            }));
                        }}
                    />
                    <ModalComponent
                        buttonType="default"
                        buttonTitle="Edit"
                        modalTitle="Edit Apartment Building"
                        content=""
                        type="Edit Apartment Building"
                        apartmentBuildingSetEditBuildingState={setEditBuildingObj}
                        apartmentBuildingEditProps={{
                            buildingNumber: record.building,
                            floorNumbers: record.floors,
                            numberOfRooms: record.rooms,
                        }}
                        handleOkay={() => {
                            handleEditLocation();
                            return Promise.resolve();
                        }}
                        setUserId={() => { }}
                        setAccessCode={() => { }}
                        selectedUserId=""
                        accessCode=""
                    />
                </div>
            ),
        },
    ];

    return (
        <div className="container">
            {/* <h1 className="mb-3">Admin Apartment Setup And Details Management</h1> */}
            <PageTitleComponent title="Admin Apartment Setup and Details Management" />
            {!tenantsExist && (
                <div className="mb-4">
                    <Button
                        type="dashed"
                        onClick={() => triggerSeedUsers()}
                        loading={seedStatus === "pending" || (seedingStatus ? seedingStatus.user_seeding.in_progress : false)}
                        disabled={seedStatus === "pending" || (seedingStatus ? seedingStatus.user_seeding.in_progress : false)}>
                        {seedingStatus && seedingStatus.user_seeding.in_progress 
                            ? "Seeding Users (This may take a minute)..." 
                            : seedingStatus && seedingStatus.user_seeding.last_complete 
                                ? "Users Seeded Successfully!" 
                                : "Seed Demo Users"}
                    </Button>
                    
                    {seedingStatus && seedingStatus.user_seeding.last_error && (
                        <div className="text-red-500 mt-2">
                            Error seeding users: {seedingStatus.user_seeding.last_error}
                        </div>
                    )}
                </div>
            )}


            <Form
                onFinish={handleSendAdminSetup}
                onValuesChange={handleFormValuesChange}
                className="admin-apartment-setup-form-container"
                layout="vertical"
                initialValues={{
                    "parking-settings": [adminSetupObject.parkingTotal, adminSetupObject.perUserParking],
                    "mail-locker-settings": adminSetupObject.lockerCount,
                    "documenso-settings": {
                        apiKey: adminSetupObject.documensoApiKey,
                        webhookSecret: adminSetupObject.documensoWebhookSecret,
                    },
                }}>
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
                        <Input
                            placeholder="Building #"
                            type="number"
                            min={0}
                        />
                        <Input
                            placeholder="# of Floors"
                            type="number"
                            min={0}
                        />
                        <Input
                            placeholder="# of Room"
                            type="number"
                            min={0}
                        />
                    </div>
                </Form.Item>
                {/* Clear Button */}
                <div className="flex gap-2 mb-3">
                    <ButtonComponent
                        title="Clear Locations"
                        type="danger"
                        icon={<DeleteOutlined />}
                        onClick={() => {
                            setLocations([]);
                        }}
                    />
                    {/* Add Location Button */}
                    <ButtonComponent
                        title="Add Location"
                        type="primary"
                        icon={<PlusOutlined />}
                        onClick={handleAddLocation}
                    />
                </div>
                <Form.Item
                    name={["parking-settings", 0]}
                    label="Available Parking Spots"
                    rules={[{ required: true, message: "Please enter available parking spots" }]}>
                    <Input
                        placeholder="Available Spots"
                        type="number"
                        min={0}
                    />
                </Form.Item>
                <Form.Item
                    name={["parking-settings", 1]}
                    label="Max Parking Spots Per User"
                    rules={[{ required: true, message: "Please enter max spots per user" }]}>
                    <Input
                        placeholder="Max Spots Per User"
                        type="number"
                        min={0}
                    />
                </Form.Item>
                <Form.Item
                    name="mail-locker-settings"
                    label="Mail Locker Settings"
                    rules={[{ required: true, message: "Please enter mail locker settings" }]}>
                    <Input
                        placeholder="Available Lockers"
                        type="number"
                        min={0}
                    />
                </Form.Item>
                
                {/* Documenso Integration Settings */}
                <div className="mb-4 mt-5">
                    <h3 className="text-lg font-semibold mb-2">Document Signing Integration (Documenso)</h3>
                    <p className="text-sm text-gray-500 mb-4">
                        Configure the connection to your Documenso instance for digital document signing.
                        These values can be found in your Documenso admin dashboard.
                    </p>
                </div>
                
                <Form.Item
                    label="Documenso API Key"
                    name={["documenso-settings", "apiKey"]}
                    tooltip="The API key generated from your Documenso admin dashboard"
                    rules={[{ required: false, message: "Please enter your Documenso API key" }]}>
                    <Input.Password
                        placeholder="Enter Documenso API key (e.g., api_xxxxxxxxxxxxxxxx)"
                        visibilityToggle={{ visible: false }}
                    />
                </Form.Item>
                
                <Form.Item
                    label="Documenso Webhook Secret"
                    name={["documenso-settings", "webhookSecret"]}
                    tooltip="The webhook secret for validating callbacks from Documenso"
                    rules={[{ required: false, message: "Please enter your Documenso webhook secret" }]}>
                    <Input.Password
                        placeholder="Enter webhook secret"
                        visibilityToggle={{ visible: false }}
                    />
                </Form.Item>
                
                <div className="bg-blue-50 p-4 rounded mb-4">
                    <p className="text-sm">
                        <strong>How to set up Documenso integration:</strong><br />
                        <span className="font-semibold">For the API Key:</span><br />
                        1. Log in to your Documenso admin dashboard<br />
                        2. Navigate to Settings → API<br />
                        3. Generate a new API key and copy it here<br />
                        <br />
                        <span className="font-semibold">For the Webhook Secret:</span><br />
                        1. Generate a secure random secret by running this command:<br />
                        <code className="bg-gray-100 px-2 py-1 rounded">openssl rand -hex 32</code><br />
                        2. Copy the generated value into this field<br />
                        3. In Documenso dashboard, go to Settings → Webhooks<br />
                        4. Create a new webhook with URL: <code className="bg-gray-100 px-2 py-1 rounded">https://api.curiousdev.net/webhooks/documenso</code><br />
                        5. Paste the same secret you entered here into Documenso's "Signing Secret" field<br />
                        6. Select events: <code>document.completed</code>, <code>document.signed</code>
                    </p>
                </div>
                
                <div className="flex items-center mb-4">
                    <div className="flex-grow border-t border-gray-300"></div>
                    <span className="mx-4 text-sm text-gray-500">Or</span>
                    <div className="flex-grow border-t border-gray-300"></div>
                </div>
                
                <Form.Item>
                    <Button 
                        type="default" 
                        onClick={() => {
                            // Generate a random webhook secret
                            const array = new Uint8Array(32);
                            window.crypto.getRandomValues(array);
                            const webhookSecret = Array.from(array)
                                .map(b => b.toString(16).padStart(2, "0"))
                                .join("");
                            
                            // Find the webhook secret input and set its value
                            const secretInput = document.querySelector('input[placeholder="Enter webhook secret"]') as HTMLInputElement;
                            if (secretInput) {
                                secretInput.value = webhookSecret;
                                // Trigger change event to update form state
                                const event = new Event('input', { bubbles: true });
                                secretInput.dispatchEvent(event);
                            }
                            
                            // Also update our state
                            setAdminSetupObject(prev => ({
                                ...prev,
                                documensoWebhookSecret: webhookSecret
                            }));
                            
                            // Show a success message
                            message.success('Webhook secret generated! Copy this to Documenso when setting up the webhook.');
                        }}
                    >
                        Generate Webhook Secret
                    </Button>
                </Form.Item>
                
                {/* <Form.Item
                    name="smtp-settings"
                    label="SMTP Settings"
                    rules={[{ required: true, message: "Please enter SMTP settings" }]}>
                    <div className="flex flex-column gap-3">
                        <Input placeholder="Url/Domain" />
                        <Input
                            placeholder="Port"
                            type="number"
                        />
                        <Input placeholder="Username" />
                        <Input placeholder="Password" />
                    </div>
                </Form.Item> */}
                <div className="flex justify-content-end gap-2">
                    {/* Cancel button */}
                    <Form.Item name="cancel">
                        <Button
                            type="default"
                            onClick={() => {
                                console.log("Cancel");
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
