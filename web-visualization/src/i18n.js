import i18n from "i18next";
import { initReactI18next } from "react-i18next";

// Helper to create resources. 
// Note: In a real production app, these would be separate JSON files loaded asynchronously.
// We implement full translations for EN, DE and partials for others for demonstration.

const commonEn = {
    nav: { summary: "Summary", rooms: "Rooms", browse: "Browse", timeline: "Timeline", settings: "Settings" },
    dashboard: { moving_day: "Moving Day", days_left: "{{count}} Days Left", view_timeline: "Tap to view full timeline", recent_activity: "Recent Activity" },
    settings: { family_sharing: "Family Sharing", privacy: "Privacy & Security", data: "Data", export_csv: "Export CSV", export_pdf: "Export PDF", legal: "Legal", terms: "Terms of Service", delete_account: "Delete Account", developed_eu: "Proudly developed in the EU 🇪🇺" }
};

const commonDe = {
    nav: { summary: "Übersicht", rooms: "Räume", browse: "Inventar", timeline: "Zeitplan", settings: "Einst." },
    dashboard: { moving_day: "Umzugstag", days_left: "Noch {{count}} Tage", view_timeline: "Tippen für Details", recent_activity: "Letzte Aktivität" },
    settings: { family_sharing: "Familienfreigabe", privacy: "Datenschutz", data: "Daten", export_csv: "CSV Exportieren", export_pdf: "PDF Exportieren", legal: "Rechtliches", terms: "Nutzungsbedingungen", delete_account: "Account löschen", developed_eu: "Stolz entwickelt in der EU 🇪🇺" }
};

const commonFr = {
    nav: { summary: "Résumé", rooms: "Pièces", browse: "Explorer", timeline: "Chronologie", settings: "Réglages" },
    settings: { developed_eu: "Développé avec fierté dans l'UE 🇪🇺" }
};

const commonEs = {
    nav: { summary: "Resumen", rooms: "Habitaciones", browse: "Explorar", timeline: "Cronología", settings: "Ajustes" },
    settings: { developed_eu: "Desarrollado con orgullo en la UE 🇪🇺" }
};

// ... Mapped languages (Fallback to EN for minor strings in this demo to save space)
const resources = {
    en: { translation: commonEn },
    de: { translation: commonDe },
    fr: { translation: { ...commonEn, ...commonFr, settings: { ...commonEn.settings, ...commonFr.settings } } },
    es: { translation: { ...commonEn, ...commonEs, settings: { ...commonEn.settings, ...commonEs.settings } } },

    // -- EU Official Languages (24 total) --
    bg: { translation: { ...commonEn, nav: { summary: "Резюме", rooms: "Стаи", browse: "Преглед", timeline: "Хронология", settings: "Настройки" } } },
    hr: { translation: { ...commonEn, nav: { summary: "Sažetak", rooms: "Sobe", browse: "Pregled", timeline: "Vremenska", settings: "Postavke" } } },
    cs: { translation: { ...commonEn, nav: { summary: "Přehled", rooms: "Místnosti", browse: "Procházet", timeline: "Časová osa", settings: "Nastavení" } } },
    da: { translation: { ...commonEn, nav: { summary: "Oversigt", rooms: "Værelser", browse: "Gennemse", timeline: "Tidslinje", settings: "Indstillinger" } } },
    nl: { translation: { ...commonEn, nav: { summary: "Overzicht", rooms: "Kamers", browse: "Bladeren", timeline: "Tijdlijn", settings: "Instellingen" } } },
    et: { translation: { ...commonEn, nav: { summary: "Kokkuvõte", rooms: "Toad", browse: "Sirvi", timeline: "Ajaskaala", settings: "Seaded" } } },
    fi: { translation: { ...commonEn, nav: { summary: "Yhteenveto", rooms: "Huoneet", browse: "Selaa", timeline: "Aikajana", settings: "Asetukset" } } },
    el: { translation: { ...commonEn, nav: { summary: "Σύνοψη", rooms: "Δωμάτια", browse: "Περιήγηση", timeline: "Χρονολόγιο", settings: "Ρυθμίσεις" } } },
    hu: { translation: { ...commonEn, nav: { summary: "Összegzés", rooms: "Szobák", browse: "Böngészés", timeline: "Idővonal", settings: "Beállítások" } } },
    ga: { translation: { ...commonEn, nav: { summary: "Achoimre", rooms: "Seomraí", browse: "Brabhsáil", timeline: "Amlíne", settings: "Socruithe" } } },
    it: { translation: { ...commonEn, nav: { summary: "Riepilogo", rooms: "Stanze", browse: "Esplora", timeline: "Cronologia", settings: "Impostazioni" } } },
    lv: { translation: { ...commonEn, nav: { summary: "Kopsavilkums", rooms: "Istabas", browse: "Pārlūkot", timeline: "Laika skala", settings: "Iestatījumi" } } },
    lt: { translation: { ...commonEn, nav: { summary: "Santrauka", rooms: "Kambariai", browse: "Naršyti", timeline: "Laiko juosta", settings: "Nustatymai" } } },
    mt: { translation: { ...commonEn, nav: { summary: "Sommarju", rooms: "Kmamar", browse: "Fittex", timeline: "Kronoloġija", settings: "Settings" } } },
    pl: { translation: { ...commonEn, nav: { summary: "Podsumowanie", rooms: "Pokoje", browse: "Przeglądaj", timeline: "Oś czasu", settings: "Ustawienia" } } },
    pt: { translation: { ...commonEn, nav: { summary: "Resumo", rooms: "Quartos", browse: "Navegar", timeline: "Cronologia", settings: "Definições" } } },
    ro: { translation: { ...commonEn, nav: { summary: "Rezumat", rooms: "Camere", browse: "Răsfoiește", timeline: "Cronologie", settings: "Setări" } } },
    sk: { translation: { ...commonEn, nav: { summary: "Súhrn", rooms: "Izby", browse: "Prehľadávať", timeline: "Časová os", settings: "Nastavenia" } } },
    sl: { translation: { ...commonEn, nav: { summary: "Povzetek", rooms: "Sobe", browse: "Brskaj", timeline: "Časovnica", settings: "Nastavitve" } } },
    sv: { translation: { ...commonEn, nav: { summary: "Översikt", rooms: "Rum", browse: "Bläddra", timeline: "Tidslinje", settings: "Inställningar" } } },

    // -- Top World Languages (Non-EU) --
    zh: { translation: { ...commonEn, nav: { summary: "摘要", rooms: "房间", browse: "浏览", timeline: "时间轴", settings: "设置" } } },
    hi: { translation: { ...commonEn, nav: { summary: "सारांश", rooms: "कमरे", browse: "ब्राउज़", timeline: "समयरेखा", settings: "सेटिंग्स" } } },
    ar: { translation: { ...commonEn, nav: { summary: "ملخص", rooms: "غرف", browse: "تصفح", timeline: "الجدول الزمني", settings: "الإعدادات" } } },
    ja: { translation: { ...commonEn, nav: { summary: "概要", rooms: "部屋", browse: "閲覧", timeline: "タイムライン", settings: "設定" } } }
};

i18n
    .use(initReactI18next)
    .init({
        resources,
        lng: "de",
        fallbackLng: "en",
        interpolation: { escapeValue: false }
    });

export default i18n;
