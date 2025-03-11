
import ModalComponent from "../components/ModalComponent";
import TableComponent from "../components/reusableComponents/TableComponent";

// Mock data for tenant table
const columns = [
    {
        title: 'Name',
        dataIndex: 'name',
        key: 'name',
    },
    {
        title: 'Email',
        dataIndex: 'email',
        key: 'email',
    },
    {
        title: 'Phone',
        dataIndex: 'phone',
        key: 'phone',
    },
    {
        title: 'Unit Number',
        dataIndex: 'unitNumber',
        key: 'unitNumber',
    },
    {
        title: 'Lease Status',
        dataIndex: 'leaseStatus',
        key: 'leaseStatus',
    },
    {
        title: 'Lease Start',
        dataIndex: 'leaseStart',
        key: 'leaseStart',
    },
    {
        title: 'Lease End',
        dataIndex: 'leaseEnd',
        key: 'leaseEnd',
    },
    {
        title: "Actions",
        key: "actions",
        render: (text: any, record: any) => (
            <div className="flex gap-2">
                <ModalComponent type="Edit Tenant" modalTitle="Edit Tenant" buttonTitle="Edit" content="Edit Tenant" handleOkay={() => { }} buttonType="primary" />
                <ModalComponent type="default" modalTitle="Delete Tenant" buttonTitle="Delete" content="Warning! Are you sure that you would like to delete the tenant?" handleOkay={() => { }} buttonType="danger" />
            </div>
        ),
    }
];

const mockTenants = [
    {
        key: '1',
        name: 'John Doe',
        email: 'john.doe@email.com',
        phone: '(555) 123-4567',
        unitNumber: '101',
        leaseStatus: <span style={{ color: 'green' }}>Active</span>,
        leaseStart: '2023-01-01',
        leaseEnd: '2024-01-01',
    },
    {
        key: '2',
        name: 'Jane Smith',
        email: 'jane.smith@email.com',
        phone: '(555) 234-5678',
        unitNumber: '202',
        leaseStatus: <span style={{ color: 'green' }}>Active</span>,
        leaseStart: '2023-03-15',
        leaseEnd: '2024-03-15',
    },
    {
        key: '3',
        name: 'Bob Wilson',
        email: 'bob.wilson@email.com',
        phone: '(555) 345-6789',
        unitNumber: '303',
        leaseStatus: <span style={{ color: 'red' }}>Expired</span>,
        leaseStart: '2023-06-01',
        leaseEnd: '2024-06-01',
    }
];


const AddTenant = () => {
    return (
        <div className="container">
            <h1>View or Add Tenants</h1>
            <div className="mb-3 flex">
                <ModalComponent type="Add Tenant" buttonTitle="Add Tenant" content="Add Tenant" buttonType="primary" handleOkay={() => { }} />
            </div>
            <TableComponent columns={columns} dataSource={mockTenants} onChange={() => { }} />
        </div>
    )
}

export default AddTenant