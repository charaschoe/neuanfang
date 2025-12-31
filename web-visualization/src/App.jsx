import React, { useState } from 'react';
import {
  LayoutGrid, Box, Map, ChevronRight, Plus, Search, Calendar, ChevronLeft,
  Settings, Camera, Share, Download, Users, Scan, CheckCircle, Shield, X,
  FileText, Globe
} from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import './index.css';
import './i18n'; // Import i18n config
import { useTranslation } from 'react-i18next';

// --- iOS Components ---

const NavBar = ({ title, leftAction, rightAction, largeTitle = true }) => (
  <div style={{ position: 'sticky', top: 0, zIndex: 100, background: 'var(--bg-primary)' }}>
    <div style={{ height: '47px' }} /> {/* Status Bar Shim */}

    <div style={{
      padding: '0 16px 8px 16px',
      display: 'flex',
      flexDirection: largeTitle ? 'column' : 'row',
      alignItems: largeTitle ? 'flex-start' : 'center',
      justifyContent: largeTitle ? 'flex-start' : 'space-between',
      minHeight: '44px'
    }}>
      {/* Small Title Bar Mode */}
      {!largeTitle && (
        <div style={{ display: 'flex', alignItems: 'center', width: '100%' }}>
          {leftAction || <div style={{ width: 24 }} />}
          <span style={{ fontWeight: 600, fontSize: '17px', flex: 1, textAlign: 'center' }}>{title}</span>
          {rightAction || <div style={{ width: 24 }} />}
        </div>
      )}

      {/* Large Title Mode */}
      {largeTitle && (
        <>
          <div style={{ width: '100%', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
            {leftAction ? leftAction : <div />}
            {rightAction}
          </div>
          <h1 className="large-title">{title}</h1>
        </>
      )}
    </div>
  </div>
);

const SearchBar = ({ placeholder }) => (
  <div style={{ padding: '0 16px 16px 16px' }}>
    <div style={{
      background: 'rgba(118, 118, 128, 0.12)',
      height: '36px',
      borderRadius: '10px',
      display: 'flex',
      alignItems: 'center',
      padding: '0 8px',
      color: 'var(--label-secondary)'
    }}>
      <Search size={16} style={{ marginRight: '6px' }} />
      <span style={{ fontSize: '17px' }}>{placeholder}</span>
    </div>
  </div>
)

const ListRow = ({ icon, color, title, subtitle, value, hasChevron = true, onClick, isDestructive }) => (
  <div className="ios-row tap-highlight" onClick={onClick}>
    {icon && (
      <div className="ios-icon-container" style={{ backgroundColor: color }}>
        {icon}
      </div>
    )}
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
      <span className="body-text" style={{ color: isDestructive ? 'var(--system-red)' : 'var(--label-primary)' }}>{title}</span>
      {subtitle && <span className="caption-1">{subtitle}</span>}
    </div>

    <div style={{ display: 'flex', alignItems: 'center' }}>
      {value && <span className="body-text" style={{ color: 'var(--label-secondary)', marginRight: '6px' }}>{value}</span>}
      {hasChevron && <ChevronRight size={20} color="var(--system-gray3)" />}
    </div>
  </div>
);

const Button = ({ label, variant = 'primary', onClick, icon }) => (
  <button
    className="tap-highlight"
    onClick={onClick}
    style={{
      width: '100%',
      padding: '14px',
      borderRadius: '14px',
      border: 'none',
      background: variant === 'primary' ? 'var(--system-blue)' : 'var(--bg-card)',
      color: variant === 'primary' ? 'white' : 'var(--system-blue)',
      fontSize: '17px',
      fontWeight: 600,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: '8px',
      margin: '8px 0'
    }}
  >
    {icon}
    {label}
  </button>
);

// --- Sub-Views ---

const BoxDetail = ({ id, onBack }) => {
  const { t } = useTranslation();
  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-primary)', paddingBottom: '100px' }}>
      <NavBar
        title={`Box #${id}`}
        largeTitle={false}
        leftAction={
          <button onClick={onBack} style={{ background: 'none', border: 'none', display: 'flex', alignItems: 'center', color: 'var(--system-blue)', fontSize: '17px', padding: 0 }}>
            <ChevronLeft size={24} style={{ marginLeft: '-8px' }} /> {t('common.back')}
          </button>
        }
        rightAction={<Share size={24} color="var(--system-blue)" />}
      />

      <div style={{ padding: '20px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <div className="ios-card" style={{ padding: '30px', display: 'flex', flexDirection: 'column', alignItems: 'center', background: 'white' }}>
          <QRCodeSVG value={`neuanfang://box/${id}`} size={160} />
          <div style={{ marginTop: '16px', fontWeight: 600, fontSize: '13px', color: 'var(--label-secondary)' }}>{t('inventory.scan_identify')}</div>
        </div>

        <Button label="NFC Tag" icon={<Scan size={20} />} variant="secondary" onClick={() => alert('Start scanning NFC tag...')} />
      </div>

      <div style={{ padding: '0 16px' }}>
        <h3 className="headline" style={{ color: 'var(--label-secondary)', textTransform: 'uppercase', marginBottom: '8px' }}>{t('inventory.contents')}</h3>
        <div className="ios-card">
          <ListRow title="Winter Jacket" subtitle={t('inventory.clothing')} hasChevron={false} />
          <ListRow title="Scarves" subtitle={t('inventory.clothing')} hasChevron={false} />
          <ListRow title="Boots" subtitle={t('inventory.shoes')} hasChevron={false} />
        </div>
      </div>
    </div>
  );
};

const TimelineView = () => {
  const { t } = useTranslation();
  return (
    <div style={{ padding: '0 16px' }}>
      <NavBar title={t('nav.timeline')} />

      <div className="ios-card" style={{ padding: '16px' }}>
        {[
          { title: t('timeline.planning'), date: "Oct 1 - Oct 15", status: "completed" },
          { title: t('timeline.decluttering'), date: "Oct 16 - Oct 20", status: "completed" },
          { title: t('timeline.packing'), date: "Oct 21 - Nov 10", status: "active" },
          { title: t('timeline.moving'), date: "Nov 15", status: "upcoming" }
        ].map((step, i) => (
          <div key={i} style={{ display: 'flex', gap: '16px', marginBottom: i === 3 ? 0 : '24px' }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <div style={{
                width: '24px', height: '24px', borderRadius: '50%',
                background: step.status === 'completed' ? 'var(--system-green)' : step.status === 'active' ? 'var(--system-blue)' : 'var(--system-gray4)',
                display: 'flex', alignItems: 'center', justifyContent: 'center'
              }}>
                {step.status === 'completed' && <CheckCircle size={14} color="white" />}
                {step.status === 'active' && <div style={{ width: 8, height: 8, background: 'white', borderRadius: '50%' }} />}
              </div>
              {i !== 3 && <div style={{ width: '2px', flex: 1, background: 'var(--system-gray5)', marginTop: '4px' }} />}
            </div>
            <div>
              <div style={{ fontWeight: 600, fontSize: '17px', color: step.status === 'upcoming' ? 'var(--label-secondary)' : 'var(--label-primary)' }}>{step.title}</div>
              <div style={{ fontSize: '15px', color: 'var(--label-secondary)', marginTop: '2px' }}>{step.date}</div>
              {step.status === 'active' && (
                <div style={{ marginTop: '8px', fontSize: '13px', color: 'var(--system-blue)', fontWeight: 500 }}>{t('timeline.in_progress')}</div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
};

const LanguageList = ({ onBack, onChange }) => {
  const { i18n } = useTranslation(); // Added useTranslation to access i18n
  const languages = [
    { code: 'en', name: 'English', flag: '🇬🇧' },
    { code: 'de', name: 'Deutsch', flag: '🇩🇪' },
    { code: 'fr', name: 'Français', flag: '🇫🇷' },
    { code: 'es', name: 'Español', flag: '🇪🇸' },
    { code: 'it', name: 'Italiano', flag: '🇮🇹' },
    { code: 'nl', name: 'Nederlands', flag: '🇳🇱' },
    { code: 'pl', name: 'Polski', flag: '🇵🇱' },
    { code: 'pt', name: 'Português', flag: '🇵🇹' },
    { code: 'zh', name: '中文', flag: '🇨🇳' },
    { code: 'hi', name: 'हिन्दी', flag: '🇮🇳' },
    { code: 'ar', name: 'العربية', flag: '🇸🇦' },
    // Add truncated list visual for others
    { code: 'sv', name: 'Svenska', flag: '🇸🇪' },
    { code: 'da', name: 'Dansk', flag: '🇩🇰' },
    { code: 'fi', name: 'Suomi', flag: '🇫🇮' },
    { code: 'el', name: 'Ελληνικά', flag: '🇬🇷' },
  ];

  return (
    <div style={{ padding: '0 0 100px 0', background: 'var(--bg-primary)', minHeight: '100vh' }}>
      <NavBar
        title="Language"
        largeTitle={false}
        leftAction={
          <button onClick={onBack} style={{ background: 'none', border: 'none', display: 'flex', alignItems: 'center', color: 'var(--system-blue)', fontSize: '17px', padding: 0 }}>
            <ChevronLeft size={24} style={{ marginLeft: '-8px' }} /> Back
          </button>
        }
      />
      <div style={{ padding: '0 16px', marginTop: '16px' }}>
        <div className="ios-card">
          {languages.map((lang, i) => (
            <ListRow
              key={lang.code}
              title={lang.name}
              icon={<span style={{ fontSize: '20px' }}>{lang.flag}</span>}
              color="transparent" // Emoji flags don't need bg
              hasChevron={i18n.language === lang.code} // Checkmark logic reused
              value={i18n.language === lang.code ? "✓" : ""}
              onClick={() => {
                onChange(lang.code);
                onBack();
              }}
            />
          ))}
        </div>
      </div>
    </div>
  )
};

const SettingsView = ({ navigate }) => {
  const { t, i18n } = useTranslation();

  const deleteAccount = () => {
    if (window.confirm("FATAL ACTION: Are you sure you want to delete your account? This cannot be undone.")) {
      alert("Account scheduled for deletion.");
    }
  }

  return (
    <div style={{ padding: '0 16px' }}>
      <NavBar title={t('nav.settings')} />

      <div style={{ display: 'flex', alignItems: 'center', marginBottom: '24px', padding: '0 16px' }}>
        <div style={{ width: '60px', height: '60px', borderRadius: '50%', background: 'var(--system-gray4)', marginRight: '16px' }} />
        <div>
          <div className="title-2">John Doe</div>
          <div className="caption-1">john.doe@example.com</div>
        </div>
      </div>

      <div className="ios-card">
        <ListRow
          icon={<Globe size={18} />}
          color="var(--system-blue)"
          title="Language"
          value={i18n.language.toUpperCase()}
          onClick={() => navigate('languages')}
        />
        <ListRow icon={<Users size={18} />} color="var(--system-blue)" title={t('settings.family_sharing')} value="2" />
        <ListRow icon={<Shield size={18} />} color="var(--system-green)" title={t('settings.privacy')} />
      </div>

      <h3 className="headline" style={{ margin: '0 0 8px 16px', color: 'var(--label-secondary)', textTransform: 'uppercase' }}>{t('settings.data')}</h3>
      <div className="ios-card">
        <ListRow icon={<Download size={18} />} color="var(--system-orange)" title={t('settings.export_csv')} />
        <ListRow icon={<Download size={18} />} color="var(--system-red)" title={t('settings.export_pdf')} />
      </div>

      <h3 className="headline" style={{ margin: '0 0 8px 16px', color: 'var(--label-secondary)', textTransform: 'uppercase' }}>{t('settings.legal')}</h3>
      <div className="ios-card">
        <ListRow icon={<FileText size={18} />} color="var(--system-gray)" title={t('settings.terms')} />
        <ListRow icon={<Shield size={18} />} color="var(--system-gray)" title={t('settings.privacy')} />
      </div>

      <div className="ios-card" style={{ marginTop: '24px' }}>
        <ListRow
          title={t('settings.delete_account')}
          isDestructive={true}
          hasChevron={false}
          onClick={deleteAccount}
        />
      </div>
      <div style={{ textAlign: 'center', padding: '20px', color: 'var(--label-tertiary)', fontSize: '13px' }}>
        <div>v1.0 (Build 342)</div>
        <div style={{ marginTop: '8px', fontWeight: 500 }}>{t('settings.developed_eu')}</div>
      </div>
    </div>
  );
};

// --- Main Views (Updated) ---

const Dashboard = ({ navigate }) => {
  const { t } = useTranslation();
  return (
    <div style={{ minHeight: '100vh', background: 'var(--bg-primary)' }}>
      <NavBar title={t('nav.summary')} rightAction={<div style={{ width: 24, height: 24, borderRadius: '50%', background: 'var(--system-gray4)' }} />} />

      <div style={{ padding: '0 16px' }}>
        <div className="ios-card" style={{ padding: '0', background: 'linear-gradient(135deg, #007AFF 0%, #5AC8FA 100%)', color: 'white' }}>
          <div style={{ padding: '20px' }} onClick={() => navigate('timeline')}>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '8px', opacity: 0.8 }}>
              <Calendar size={18} style={{ marginRight: '6px' }} />
              <span className="headline" style={{ fontSize: '13px', textTransform: 'uppercase' }}>{t('dashboard.moving_day')}</span>
            </div>
            <div className="large-title" style={{ marginTop: 0 }}>{t('dashboard.days_left', { count: 14 })}</div>
            <p className="body-text" style={{ opacity: 0.9 }}>{t('dashboard.view_timeline')}</p>
          </div>
        </div>

        <h3 className="headline" style={{ margin: '24px 0 10px 16px', color: 'var(--label-secondary)', textTransform: 'uppercase' }}>{t('dashboard.recent_activity')}</h3>

        <div className="ios-card">
          <ListRow
            icon={<Box size={18} />}
            color="var(--system-orange)"
            title="Kitchen Box #4"
            subtitle={t('dashboard.added_items', { count: 12 })}
            value={t('dashboard.just_now')}
            onClick={() => navigate('box/4')}
          />
          <ListRow
            icon={<Map size={18} />}
            color="var(--system-green)"
            title="Living Room"
            subtitle={t('dashboard.packing_completed')}
            value="2h"
          />
        </div>
      </div>
    </div>
  );
};

const Rooms = () => {
  const { t } = useTranslation();
  const rooms = ['living_room', 'kitchen', 'bedroom', 'office', 'bathroom', 'basement'];

  return (
    <div style={{ minHeight: '100vh' }}>
      <NavBar title={t('nav.rooms')} rightAction={<Plus size={22} color="var(--system-blue)" />} />

      <div style={{ padding: '0 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
        {rooms.map((roomCode, i) => (
          <div key={roomCode} className="tap-highlight" style={{
            background: 'var(--bg-card)',
            borderRadius: '16px',
            padding: '16px',
            height: '100px',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            backdropFilter: 'var(--material-regular)',
            WebkitBackdropFilter: 'var(--material-regular)',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <div style={{
                width: '32px', height: '32px', borderRadius: '50%',
                background: i % 2 === 0 ? 'rgba(255,149,0,0.1)' : 'rgba(52,199,89,0.1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center'
              }}>
                <Map size={18} color={i % 2 === 0 ? 'var(--system-orange)' : 'var(--system-green)'} />
              </div>
            </div>
            <div>
              <div className="headline">{t(`rooms.${roomCode}`)}</div>
              <div className="caption-1">{t('rooms.box_count', { count: 4 })}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

const Items = ({ navigate }) => {
  const { t } = useTranslation();
  const [isScanning, setIsScanning] = useState(false);

  if (isScanning) {
    return (
      <div style={{ position: 'fixed', inset: 0, background: 'black', zIndex: 200, color: 'white' }}>
        <div style={{ padding: '20px', display: 'flex', justifyContent: 'space-between' }}>
          <X onClick={() => setIsScanning(false)} />
          <span style={{ fontWeight: 600 }}>{t('inventory.ai_vision')}</span>
          <div style={{ width: 24 }} />
        </div>
        <div style={{ height: '60%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ width: '250px', height: '250px', border: '2px solid rgba(255,255,255,0.5)', borderRadius: '20px' }} />
        </div>
        <div style={{ textAlign: 'center', padding: '20px' }}>
          <p style={{ marginBottom: '20px' }}>{t('inventory.camera_instruction')}</p>
          <div style={{ width: 70, height: 70, borderRadius: '50%', border: '4px solid white', margin: '0 auto', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <div style={{ width: 58, height: 58, background: 'white', borderRadius: '50%' }} onClick={() => {
              alert("AI Recognized: 'Vintage Lamp'. Fragility: High. Recommended Box: 'Living Room 2'");
              setIsScanning(false);
            }} />
          </div>
        </div>
      </div>
    )
  }

  return (
    <div style={{ minHeight: '100vh' }}>
      <NavBar title={t('nav.browse')} rightAction={<Camera size={22} color="var(--system-blue)" onClick={() => setIsScanning(true)} />} />
      <SearchBar placeholder={t('inventory.search')} />

      <div style={{ padding: '0 16px' }}>
        <div className="ios-card">
          <ListRow title={t('inventory.all_items')} value="142" hasChevron />
          <ListRow title={t('inventory.fragile')} value="12" hasChevron />
        </div>

        <h3 className="headline" style={{ margin: '24px 0 10px 16px', color: 'var(--label-secondary)', textTransform: 'uppercase' }}>Boxes</h3>

        <div className="ios-card">
          {[1, 2, 3, 4, 5].map(id => (
            <ListRow
              key={id}
              icon={<Box size={18} />}
              color="var(--system-gray)"
              title={`Box #${id}`}
              subtitle="Kitchen • Plates, Cutlery"
              value={t('common.status_packed')}
              onClick={() => navigate(`box/${id}`)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

// --- App Navigation ---

const TabBar = ({ active, onChange }) => {
  const { t } = useTranslation();
  const tabs = [
    { id: 'dashboard', icon: LayoutGrid, label: t('nav.summary') },
    { id: 'rooms', icon: Map, label: t('nav.rooms') },
    { id: 'items', icon: Box, label: t('nav.browse') },
    { id: 'timeline', icon: Calendar, label: t('nav.timeline') },
    { id: 'settings', icon: Settings, label: t('nav.settings') },
  ];

  return (
    <div className="tab-bar">
      {tabs.map(tab => {
        const isActive = active === tab.id;
        return (
          <div
            key={tab.id}
            className="tap-highlight"
            onClick={() => onChange(tab.id)}
            style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              paddingTop: '6px'
            }}
          >
            <tab.icon strokeWidth={isActive ? 2.5 : 2} size={26} color={isActive ? 'var(--system-blue)' : 'var(--system-gray2)'} />
            <span style={{
              fontSize: '10px',
              marginTop: '4px',
              fontWeight: 500,
              color: isActive ? 'var(--system-blue)' : 'var(--system-gray2)'
            }}>
              {tab.label}
            </span>
          </div>
        )
      })}
    </div>
  )
};

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [navStack, setNavStack] = useState([]);
  const { t } = useTranslation();

  const navigate = (path) => {
    setNavStack([...navStack, path]);
  };

  const goBack = () => {
    setNavStack(navStack.slice(0, -1));
  };

  const currentView = navStack.length > 0 ? navStack[navStack.length - 1] : null;

  if (currentView) {
    if (currentView.startsWith('box/')) {
      return <BoxDetail id={currentView.split('/')[1]} onBack={goBack} />;
    }
    if (currentView === 'timeline') {
      return (
        <div style={{ minHeight: '100vh' }}>
          <div style={{ paddingBottom: '84px' }}>
            <TimelineView />
          </div>
          <button onClick={goBack} style={{ position: 'fixed', bottom: 100, left: '50%', transform: 'translateX(-50%)', background: 'var(--system-blue)', color: 'white', padding: '8px 16px', borderRadius: '20px', border: 'none' }}>{t('common.close')}</button>
        </div>
      )
    }
    if (currentView === 'languages') {
      return <LanguageList onBack={goBack} onChange={(lang) => i18n.changeLanguage(lang)} />;
    }
  }

  return (
    <>
      <div style={{ paddingBottom: '84px' }}>
        {activeTab === 'dashboard' && <Dashboard navigate={navigate} />}
        {activeTab === 'rooms' && <Rooms />}
        {activeTab === 'items' && <Items navigate={navigate} />}
        {activeTab === 'timeline' && <TimelineView />}
        {activeTab === 'settings' && <SettingsView navigate={navigate} />}
      </div>

      <TabBar active={activeTab} onChange={(id) => {
        setActiveTab(id);
        setNavStack([]);
      }} />
    </>
  );
}

export default App;
