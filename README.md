# Evidence-For-Fivem
# 🕵️‍♂️ Advanced Evidence System (Ox Ecosystem)

FiveM sunucuları için **ox_lib**, **ox_inventory** ve **ox_target** altyapısı kullanılarak hazırlanmış, yüksek performanslı ve detaylı bir delil sistemidir. Mermi kovanları, kan izleri, DNA analizleri ve adli tıp raporlama süreçlerini içerir.

![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![FiveM](https://img.shields.io/badge/FiveM-F43F5E?style=for-the-badge&logo=fivem&logoColor=white)
![Ox](https://img.shields.io/badge/Ox_Lib-Success?style=for-the-badge)

## ✨ Özellikler

* **🚀 Yüksek Optimizasyon:** `lib.points` kullanımı sayesinde 0.00ms idle performansı. Deliller sadece el feneri açıldığında renderlanır.
* **🩸 Detaylı Delil Tipleri:**
    * **Mermi Kovanları:** Silah seri numarası, modeli ve atış zamanı kaydedilir.
    * **Kan İzleri:** Yaralanan oyuncunun DNA'sı (CitizenID) ve kan grubu kaydedilir.
    * **Bozulma Süresi:** Kan delilleri belirli bir süre sonra (Config ayarlı) bozulur ve analiz edilemez hale gelir.
* **🧤 Eldiven Sistemi:** Eldiven takan oyuncular mermi kovanlarında parmak izi (seri no) bırakmaz.
* **🔦 Fener ve Görünürlük:** Deliller çıplak gözle görülemez, sadece silah feneri veya el feneri açıkken görünür.
* **🎒 Toplama ve Temizleme:**
    * **[E] Tuşu:** Delil toplar (Envanterde `empty_evidence_bag` gerektirir).
    * **[G] Tuşu:** Delili temizler/yok eder (Envanterde `cleaning_cloth` gerektirir).
* **🧪 Adli Tıp Laboratuvarı:**
    * Detaylı analiz raporu (Tarih, Saat, Silah Hash, Seri No, DNA).
    * Analiz animasyonları.
    * **SQL Arşivleme:** Yapılan her analiz veritabanına kaydedilir ve geriye dönük incelenebilir.
* **🛡️ Güvenlik:** Hilecilerin uzaktan delil spawn etmesini engelleyen mesafe korumaları.

## 📦 Gereksinimler

Bu scriptin çalışması için aşağıdaki kaynakların kurulu olması gerekir:

* [ox_lib](https://github.com/overextended/ox_lib)
* [ox_inventory](https://github.com/overextended/ox_inventory)
* [ox_target](https://github.com/overextended/ox_target)
* [oxmysql](https://github.com/overextended/oxmysql)
* **Framework:** QB-Core veya ESX (Otomatik algılar)

## 🛠️ Kurulum

1.  Bu repoyu indirin ve sunucu kaynakları klasörüne (`resources`) atın.
2.  `server.cfg` dosyasına ekleyin:
    ```cfg
    ensure ox_lib
    ensure ox_inventory
    ensure ox_target
    ensure oxmysql
    ensure luminary-evidence
    ```
3.  **SQL Dosyasını Okutun:** Aşağıdaki kodu veritabanınızda çalıştırın.
    ```sql
    CREATE TABLE IF NOT EXISTS `evidence_archive` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `officer_name` varchar(100) DEFAULT 'Bilinmiyor',
      `evidence_type` varchar(50) DEFAULT NULL,
      `report_data` longtext DEFAULT NULL,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ```
4.  **Itemları Ekleyin:** `ox_inventory/data/items.lua` dosyasının en altına şu satırları ekleyin:

    ```lua
    ["evidence_bullet"] = {
        label = "Mermi Kovanı",
        weight = 10,
        stack = false,
        close = true,
        description = "Olay yerinden toplanmış bir mermi kovanı."
    },
    ["evidence_blood"] = {
        label = "Kan Örneği",
        weight = 10,
        stack = false,
        close = true,
        description = "Adli tıp analizi gerektiren bir kan örneği."
    },
    ["empty_evidence_bag"] = {
        label = "Boş Delil Torbası",
        weight = 5,
        stack = true,
        close = true,
        description = "Olay yerinden delil toplamak için kullanılır."
    },
    ["cleaning_cloth"] = {
        label = "Temizlik Bezi",
        weight = 50,
        stack = true,
        close = true,
        description = "Kanları temizlemek için kullanılır."
    },
    ["bloody_rag"] = {
        label = "Kanlı Bez",
        weight = 60,
        stack = false,
        close = true,
        description = "Kan temizlemede kullanılmış kirli bez."
    },
    ```

## ⚙️ Yapılandırma (Config)

`config.lua` üzerinden şunları ayarlayabilirsiniz:

* **BloodDegradeTime:** Kanın kaç saniyede bozulacağı.
* **Gloves:** Hangi eldivenlerin parmak izi bırakmayacağı.
* **Labs:** Adli tıp laboratuvarlarının koordinatları.

## 🎮 Kullanım

1.  Bir oyuncu ateş ettiğinde yere kovan düşer (5 saniye cooldown).
2.  Bir oyuncu yaralandığında yere kan düşer.
3.  Delilleri görmek için **El Feneri** veya **Silah Feneri** açın.
4.  Delilin yanına gidin:
    * **[E]** basarak toplayın (Üzerinizde `Boş Delil Torbası` olmalı).
    * **[G]** basarak temizleyin (Üzerinizde `Temizlik Bezi` olmalı).
5.  Toplanan delilleri Laboratuvara götürün, target ile menüyü açın ve analiz edin.
6.  Eski raporlara **"Arşiv Kayıtları"** menüsünden ulaşabilirsiniz.
