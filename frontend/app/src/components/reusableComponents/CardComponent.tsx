import React from "react";
import { ButtonComponentProps } from "./ButtonComponent";
import Card from "antd/es/card/Card";

interface CardComponentProps {
    title: string;
    description: any;
    icon?: any;
    button?: any;
    hoverable: boolean;
    value?: number;
}

export const CardComponent = (props: CardComponentProps) => {
    return (
        <>
            <Card
                //TODO: JJ make these styles better
                title={props.title}
                hoverable={props.hoverable}
                className="card pb-2">
                <div className="card-content">
                    {props.icon && <span>{props.icon}</span>}

                    {props.description && <span className="text-muted py-2">{props.description}</span>}
                    {props.value && <span className="text-muted fs-1 py-2">{props.value}</span>}

                    {props.button && <span className="pb-2">{props.button}</span>}
                </div>
            </Card>
        </>
    );
};
