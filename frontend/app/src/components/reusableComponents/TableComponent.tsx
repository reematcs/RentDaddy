import React from "react";
import { Table } from "antd";
import type { TableColumnsType, TableProps } from "antd";

interface TableComponentProps<T> {
    columns: TableColumnsType<T>;
    dataSource?: T[];
    onChange?: TableProps<T>["onChange"]; // Add onChange support
}

const TableComponent = <T,>({ columns, dataSource = [], onChange }: TableComponentProps<T>) => {
    return (
        <Table<T>
            columns={columns}
            dataSource={dataSource}
            onChange={onChange} // Ensure the prop is properly passed
            className="table"
            rowKey={(record) => (record as any).key || JSON.stringify(record)}
        />
    );
};

export default TableComponent;
