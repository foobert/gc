import React from 'react';

export default function TextFilterEntry(props) {
    return (
        <div>{ props.label } <span onClick={props.onRemoveClick}>X</span></div>
    );
}

TextFilterEntry.propTypes = {
    label: React.PropTypes.string.isRequired,
    onRemoveClick: React.PropTypes.func.isRequired,
};
