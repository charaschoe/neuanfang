import React from 'react';

export const GlassCard = ({ children, className = '', depth = 'elevated', onClick }) => {
    const depthClass = depth === 'floating' ? 'shadow-float' : 'shadow-sm';

    return (
        <div
            className={`glass-panel ${depthClass} ${className} ${onClick ? 'tap-highlight' : ''}`}
            onClick={onClick}
            style={{ padding: '20px', overflow: 'hidden', position: 'relative' }}
        >
            {/* Glossy overlay effect */}
            <div style={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                height: '50%',
                background: 'linear-gradient(180deg, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 100%)',
                pointerEvents: 'none'
            }} />
            {children}
        </div>
    );
};
