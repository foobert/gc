import React from 'react';

export default function LabelPlural(props) {
    return <span>{`${props.count} ${props.count === 1 ? props.singular : props.plural}`}</span>;
}

LabelPlural.propTypes = {
    count: React.PropTypes.number.isRequired,
    singular: React.PropTypes.string.isRequired,
    plural: React.PropTypes.string.isRequired,
};
