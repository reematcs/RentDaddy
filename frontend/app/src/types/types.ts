
export interface LeaseData {
    key: number;
    tenantName: string;
    apartment: string;
    leaseStartDate: string;
    leaseEndDate: string;
    rentAmount: number;
    status: string;
}


// Defines a generic type for user-related tables
export interface UserData {
    key: React.Key;
    name: string;
    email: string;
    role: "admin" | "user";
}
