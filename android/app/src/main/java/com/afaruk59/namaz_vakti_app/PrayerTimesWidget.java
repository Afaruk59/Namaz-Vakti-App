package com.afaruk59.namaz_vakti_app;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Configuration;
import android.widget.RemoteViews;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Calendar;
import android.os.AsyncTask;
import android.util.Log;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserFactory;

import com.afaruk59.namaz_vakti_app.R;

public class PrayerTimesWidget extends AppWidgetProvider {

    private static final String PREFS_NAME = "FlutterSharedPreferences";
    private static final String BASE_URL = "https://www.namazvakti.com/XML.php?cityID=";
    private static final String ACTION_REFRESH = "com.afaruk59.namaz_vakti_app.ACTION_REFRESH";
    private static AsyncTask<Object, Void, WidgetData> mAsyncTask;

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);
        if (ACTION_REFRESH.equals(intent.getAction()) || 
            Intent.ACTION_CONFIGURATION_CHANGED.equals(intent.getAction())) {
            AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
            int[] appWidgetIds = appWidgetManager.getAppWidgetIds(new android.content.ComponentName(context, PrayerTimesWidget.class));
            onUpdate(context, appWidgetManager, appWidgetIds);
        }
    }

    @Override
    public void onEnabled(Context context) {
        super.onEnabled(context);
        AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
        int[] appWidgetIds = appWidgetManager.getAppWidgetIds(new android.content.ComponentName(context, PrayerTimesWidget.class));
        
        // Widget ilk eklendiğinde hemen güncelleme yap
        if (appWidgetIds != null && appWidgetIds.length > 0) {
            for (int appWidgetId : appWidgetIds) {
                RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);
                applyTheme(context, views);
                updateAppWidget(context, appWidgetManager, appWidgetId);
            }
        }
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        // Önceki AsyncTask'i iptal et
        if (mAsyncTask != null) {
            mAsyncTask.cancel(true);
            mAsyncTask = null;
        }
        
        // Her widget için güncelleme yap
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);
            
            // Yükleniyor durumunu göster
            views.setTextViewText(R.id.imsakTime, "...");
            views.setTextViewText(R.id.gunesTime, "...");
            views.setTextViewText(R.id.ogleTime, "...");
            views.setTextViewText(R.id.ikindiTime, "...");
            views.setTextViewText(R.id.aksamTime, "...");
            views.setTextViewText(R.id.yatsiTime, "...");
            views.setTextViewText(R.id.lastUpdate, context.getString(R.string.last_update, "..."));
            
            // Tema ayarlarını uygula
            applyTheme(context, views);
            
            // Widget'ı güncelle
            appWidgetManager.updateAppWidget(appWidgetId, views);
            
            // Veri güncelleme işlemini başlat
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    @Override
    public void onDisabled(Context context) {
        super.onDisabled(context);
        if (mAsyncTask != null) {
            mAsyncTask.cancel(true);
            mAsyncTask = null;
        }
    }

    private static String getFormattedDateTime(Context context) {
        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm", Locale.getDefault());
        Date now = new Date();
        return context.getString(R.string.last_update, timeFormat.format(now));
    }

    private static void applyTheme(Context context, RemoteViews views) {
        int nightModeFlags = context.getResources().getConfiguration().uiMode & 
                            Configuration.UI_MODE_NIGHT_MASK;
        boolean isDarkTheme = nightModeFlags == Configuration.UI_MODE_NIGHT_YES;

        // Arka plan ve metin renklerini ayarla
        views.setInt(R.id.widgetLayout, "setBackgroundResource", 
            isDarkTheme ? R.drawable.widget_background_dark : R.drawable.widget_background_light);

        int textColor = context.getResources().getColor(
            isDarkTheme ? R.color.widget_text_color_dark : R.color.widget_text_color_light);
        int textColorSecondary = context.getResources().getColor(
            isDarkTheme ? R.color.widget_text_color_secondary_dark : R.color.widget_text_color_secondary_light);

        // Ana metin renkleri
        views.setTextColor(R.id.widgetTitle, textColor);
        views.setTextColor(R.id.imsakTime, textColor);
        views.setTextColor(R.id.gunesTime, textColor);
        views.setTextColor(R.id.ogleTime, textColor);
        views.setTextColor(R.id.ikindiTime, textColor);
        views.setTextColor(R.id.aksamTime, textColor);
        views.setTextColor(R.id.yatsiTime, textColor);

        // Başlık renkleri
        int[] titleIds = {
            R.id.imsakLabel, R.id.gunesLabel, R.id.ogleLabel,
            R.id.ikindiLabel, R.id.aksamLabel, R.id.yatsiLabel
        };
        for (int id : titleIds) {
            views.setTextColor(id, textColor);
        }

        // İkincil metin rengi
        views.setTextColor(R.id.lastUpdate, textColorSecondary);
    }

    static void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        try {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);
            
            // Tema ayarlarını uygula
            applyTheme(context, views);
            
            // Widget'a tıklandığında uygulamayı açmak için intent
            Intent openAppIntent = new Intent(context, MainActivity.class);
            openAppIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            PendingIntent openAppPendingIntent = PendingIntent.getActivity(
                context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            views.setOnClickPendingIntent(R.id.widgetLayout, openAppPendingIntent);
            
            // Yenileme butonu için intent oluştur
            Intent refreshIntent = new Intent(context, PrayerTimesWidget.class);
            refreshIntent.setAction(ACTION_REFRESH);
            PendingIntent refreshPendingIntent = PendingIntent.getBroadcast(
                context, 0, refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
            views.setOnClickPendingIntent(R.id.refreshButton, refreshPendingIntent);

            // Yükleniyor durumunu göster
            views.setTextViewText(R.id.widgetTitle, "...");
            views.setTextViewText(R.id.imsakTime, "...");
            views.setTextViewText(R.id.gunesTime, "...");
            views.setTextViewText(R.id.ogleTime, "...");
            views.setTextViewText(R.id.ikindiTime, "...");
            views.setTextViewText(R.id.aksamTime, "...");
            views.setTextViewText(R.id.yatsiTime, "...");
            views.setTextViewText(R.id.lastUpdate, context.getString(R.string.last_update, "..."));
            
            // Widget'ı güncelle
            appWidgetManager.updateAppWidget(appWidgetId, views);
            
            // Yeni AsyncTask oluştur
            mAsyncTask = new AsyncTask<Object, Void, WidgetData>() {
                private final Context mContext = context;
                private final AppWidgetManager mAppWidgetManager = appWidgetManager;
                private final int mAppWidgetId = appWidgetId;
                private final RemoteViews mViews = views;

                @Override
                protected WidgetData doInBackground(Object... params) {
                    try {
                        // SharedPreferences işlemleri
                        SharedPreferences prefs = mContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
                        String locationId = prefs.getString("flutter.location", "");
                        String cityName = prefs.getString("flutter.name", mContext.getString(R.string.app_name));

                        if (locationId.isEmpty()) {
                            return new WidgetData(cityName, null);
                        }

                        // API'den veri çekme
                        URL url = new URL(BASE_URL + locationId);
                        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                        connection.setRequestMethod("GET");
                        connection.setConnectTimeout(10000);
                        connection.setReadTimeout(10000);
                        
                        BufferedReader reader = new BufferedReader(
                            new InputStreamReader(connection.getInputStream())
                        );
                        
                        StringBuilder response = new StringBuilder();
                        String line;
                        while ((line = reader.readLine()) != null) {
                            response.append(line);
                        }
                        reader.close();

                        // XML parse işlemi
                        XmlPullParserFactory factory = XmlPullParserFactory.newInstance();
                        XmlPullParser parser = factory.newPullParser();
                        parser.setInput(new StringReader(response.toString()));

                        Calendar calendar = Calendar.getInstance();
                        final int currentDay = calendar.get(Calendar.DAY_OF_MONTH);
                        final int currentMonth = calendar.get(Calendar.MONTH) + 1;

                        String[] times = null;
                        int eventType = parser.getEventType();
                        
                        while (eventType != XmlPullParser.END_DOCUMENT) {
                            if (eventType == XmlPullParser.START_TAG && parser.getName().equals("prayertimes")) {
                                String dayStr = parser.getAttributeValue(null, "day");
                                String monthStr = parser.getAttributeValue(null, "month");
                                
                                if (dayStr != null && monthStr != null) {
                                    int day = Integer.parseInt(dayStr);
                                    int month = Integer.parseInt(monthStr);
                                    
                                    if (day == currentDay && month == currentMonth) {
                                        parser.next();
                                        if (parser.getEventType() == XmlPullParser.TEXT) {
                                            String text = parser.getText().trim();
                                            times = text.split("\\s+");
                                            break;
                                        }
                                    }
                                }
                            }
                            eventType = parser.next();
                        }
                        
                        return new WidgetData(cityName, times);
                        
                    } catch (Exception e) {
                        Log.e("PrayerTimesWidget", "Error in doInBackground", e);
                        return null;
                    }
                }
                
                @Override
                protected void onPostExecute(WidgetData data) {
                    if (!isCancelled() && data != null) {
                        mViews.setTextViewText(R.id.widgetTitle, data.cityName);
                        
                        if (data.times != null && data.times.length > 13) {
                            try {
                                String imsak = data.times[0];
                                String gunes = data.times[2];
                                String ogle = data.times[5];
                                String ikindi = data.times[6];
                                String aksam = data.times[9];
                                String yatsi = data.times[11];

                                mViews.setTextViewText(R.id.imsakTime, imsak);
                                mViews.setTextViewText(R.id.gunesTime, gunes);
                                mViews.setTextViewText(R.id.ogleTime, ogle);
                                mViews.setTextViewText(R.id.ikindiTime, ikindi);
                                mViews.setTextViewText(R.id.aksamTime, aksam);
                                mViews.setTextViewText(R.id.yatsiTime, yatsi);
                                
                                mViews.setTextViewText(R.id.lastUpdate, getFormattedDateTime(mContext));
                            } catch (Exception e) {
                                Log.e("PrayerTimesWidget", "Error parsing times", e);
                                setDefaultTimes(mContext, mViews, mAppWidgetManager, mAppWidgetId);
                            }
                        } else {
                            setDefaultTimes(mContext, mViews, mAppWidgetManager, mAppWidgetId);
                        }
                    } else {
                        setDefaultTimes(mContext, mViews, mAppWidgetManager, mAppWidgetId);
                    }
                    
                    // Tema ayarlarını tekrar uygula
                    applyTheme(mContext, mViews);
                    mAppWidgetManager.updateAppWidget(mAppWidgetId, mViews);
                }
            };
            mAsyncTask.execute();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void setDefaultTimes(Context context, RemoteViews views, AppWidgetManager appWidgetManager, int appWidgetId) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        String cityName = prefs.getString("flutter.name", context.getString(R.string.app_name));
        views.setTextViewText(R.id.widgetTitle, cityName);

        views.setTextViewText(R.id.imsakTime, "...");
        views.setTextViewText(R.id.gunesTime, "...");
        views.setTextViewText(R.id.ogleTime, "...");
        views.setTextViewText(R.id.ikindiTime, "...");
        views.setTextViewText(R.id.aksamTime, "...");
        views.setTextViewText(R.id.yatsiTime, "...");
        views.setTextViewText(R.id.lastUpdate, getFormattedDateTime(context));
        
        // Tema ayarlarını uygula
        applyTheme(context, views);
        
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }

    private static class WidgetData {
        final String cityName;
        final String[] times;

        WidgetData(String cityName, String[] times) {
            this.cityName = cityName;
            this.times = times;
        }
    }
} 