import { promptAction } from '@kit.ArkUI';

// 定義店鋪數據結構
interface Shop {
  name: string;
  type: string;
  level: string;
  score: number;
}

@Entry
@Component
struct Index {
  // --- 狀態變量 ---
  @State resultText: string = '今天吃什麼？';
  @State resultSubText: string = '分類均等 + 智能權重 + 補償Buff';
  @State buffText: string = '';
  @State isRolling: boolean = false;

  @State inputName: string = '';
  @State inputType: string = '吃食堂';

  // 評價體系：從差到好排列（索引 0=拉完了, 4=夯）
  private levels: string[] = ['拉完了', 'NPC', '人上人', '頂級', '夯'];
  @State selectedLevelIndex: number = 4; // 默認選中「夯」

  // 四大金剛分類
  private categories: string[] = ['吃食堂', '點外賣', '出去吃', '吃泡面'];

  // 補償機制 Buff 池
  private treatBuffs: string[] = ['必須加個蛋補償下！🥚', '來杯奶茶寬慰自己 🥤', '加份炸雞，別虧待自己 🍗', '搞個冰淇淋甜甜嘴 🍦', '多加點辣，化悲憤為食慾 🌶️'];
  private saveBuffs: string[] = ['省點錢，今天不喝水 💧', '忍住，別加蛋了 🥚❌', '拒絕奶茶，節省預算 🚫', '原汁原味，不加額外配菜 🙅', '點份青菜，平淡才是真 🥬'];

  // 初始數據
  // 中山大學廣州校區南校園（康樂園）專屬初始數據
  @State shops: Shop[] = [
    // --- 食堂類 ---
    { name: '松濤園焗飯', type: '吃食堂', level: '夯', score: 5 },
    { name: '逸仙精緻菜', type: '吃食堂', level: '頂級', score: 4 },
    { name: '春暉園二樓扒飯', type: '吃食堂', level: '人上人', score: 3 },
    { name: '學一食堂大鍋菜', type: '吃食堂', level: 'NPC', score: 2 },

    // --- 出去吃（南門/西門周邊） ---
    { name: '南門口潮汕牛肉店', type: '出去吃', level: '夯', score: 5 },
    { name: '新港西路麥當勞', type: '出去吃', level: '人上人', score: 3 },
    { name: '下渡路卜卜貝', type: '出去吃', level: '頂級', score: 4 },
    { name: '西門口桂林米粉', type: '出去吃', level: 'NPC', score: 2 },

    // --- 點外賣（熱門商圈） ---
    { name: '瑞幸咖啡 (新港西路店)', type: '點外賣', level: '夯', score: 5 },
    { name: '某家燒臘拼盤', type: '點外賣', level: '頂級', score: 4 },
    { name: '黃燜雞米飯', type: '點外賣', level: 'NPC', score: 2 },
    { name: '深夜炸雞樂趣', type: '點外賣', level: '人上人', score: 3 },

    // --- 吃泡面（救急系列） ---
    { name: '合味道海鮮味', type: '吃泡面', level: '夯', score: 5 },
    { name: '火雞面 (加芝士版)', type: '吃泡面', level: '頂級', score: 4 },
    { name: '康師傅紅燒牛肉', type: '吃泡面', level: 'NPC', score: 2 },
    { name: '白象大骨麵', type: '吃泡面', level: '人上人', score: 3 }
  ];

  @State editingIndex: number = -1;

  // --- 核心邏輯：隨機抽取 ---
  rollFood() {
    if (this.isRolling) return;
    this.isRolling = true;
    this.buffText = ''; // 開始滾動時清空 Buff

    let count = 0;
    let intervalId = setInterval(() => {
      // 滾動期間：分類等機率跳動
      this.resultText = this.categories[Math.floor(Math.random() * this.categories.length)];
      count++;
      if (count > 15) {
        clearInterval(intervalId);
        this.finishRolling();
      }
    }, 80);
  }

  finishRolling() {
    // 1. 第一層：分類均等隨機 (每個大項 25% 幾率)
    let finalType = this.resultText;
    let matchedShops = this.shops.filter(s => s.type === finalType);

    let finalScore = 3; // 預設中間分

    if (matchedShops.length > 0) {
      // 2. 第二層：按 5:4:3:2:1 權重篩選店鋪
      let weightPool: Shop[] = [];
      matchedShops.forEach(shop => {
        for (let i = 0; i < shop.score; i++) {
          weightPool.push(shop);
        }
      });

      let pickedShop = weightPool[Math.floor(Math.random() * weightPool.length)];
      this.resultText = pickedShop.name;
      this.resultSubText = `【${finalType}】 評價等級：${pickedShop.level}`;
      finalScore = pickedShop.score;
    } else {
      this.resultSubText = "該分類暫無記錄，直接去吧！";
    }

    // 3. 第三層：觸發補償性 Buff
    this.generateBuff(finalScore);

    this.isRolling = false;
  }

  // 補償機制：好店省錢，差店加餐
  generateBuff(score: number) {
    if (Math.random() > 0.3) { // 70% 的幾率出現建議
      if (score >= 4) {
        // 夯/頂級 -> 省錢
        let idx = Math.floor(Math.random() * this.saveBuffs.length);
        this.buffText = "✨ 好店省錢建議： " + this.saveBuffs[idx];
      } else if (score <= 2) {
        // NPC/拉完了 -> 補償
        let idx = Math.floor(Math.random() * this.treatBuffs.length);
        this.buffText = "✨ 避雷補償 Buff： " + this.treatBuffs[idx];
      } else {
        this.buffText = "✨ 今日Buff： 正常發揮，不加不減";
      }
    } else {
      this.buffText = "✨ 今日Buff： 隨緣吃，不糾結";
    }
  }

  // --- 管理功能：增刪改 ---
  saveShop() {
    if (this.inputName.trim() === '') {
      promptAction.showToast({ message: '請輸入店名' });
      return;
    }
    const newShop: Shop = {
      name: this.inputName,
      type: this.inputType,
      level: this.levels[this.selectedLevelIndex],
      score: this.selectedLevelIndex + 1
    };
    if (this.editingIndex === -1) {
      this.shops.push(newShop);
      promptAction.showToast({ message: '已收錄' });
    } else {
      this.shops[this.editingIndex] = newShop;
      this.editingIndex = -1;
      promptAction.showToast({ message: '修改成功' });
    }
    this.inputName = '';
  }

  deleteShop(index: number) {
    this.shops.splice(index, 1);
    promptAction.showToast({ message: '已刪除' });
  }

  startEdit(index: number) {
    this.editingIndex = index;
    const shop = this.shops[index];
    this.inputName = shop.name;
    this.inputType = shop.type;
    this.selectedLevelIndex = this.levels.indexOf(shop.level);
  }

  getLevelColor(level: string) {
    const colorMap: Record<string, string> = {
      '夯': '#D32F2F', '頂級': '#F57C00', '人上人': '#388E3C', 'NPC': '#757575', '拉完了': '#212121'
    };
    return colorMap[level] || '#666666';
  }

  build() {
    Column() {
      // --- 頂部展示區 ---
      Column({ space: 15 }) {
        Text(this.resultText).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#E64A19').textAlign(TextAlign.Center)
        Text(this.resultSubText).fontSize(16).fontColor('#666666')

        if (this.buffText !== '') {
          Text(this.buffText).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#007DFF')
            .padding(12).backgroundColor('#E3F2FD').borderRadius(12)
        }

        Button(this.isRolling ? '算法計算中...' : '幫我決定')
          .width('60%').height(45).onClick(() => this.rollFood())
      }
      .padding(30).width('100%').backgroundColor('#FFFFFF')
      .borderRadius({ bottomLeft: 25, bottomRight: 25 }).shadow({ radius: 8, color: '#15000000' })

      // --- 輸入與編輯區 ---
      Column({ space: 10 }) {
        Text(this.editingIndex === -1 ? '美食審判台' : '重新評價中...').fontSize(18).fontWeight(FontWeight.Bold).width('100%')
        TextInput({ placeholder: '輸入店名或食物', text: this.inputName }).onChange((v) => this.inputName = v)
        Row({ space: 8 }) {
          Select([{ value: '吃食堂' }, { value: '點外賣' }, { value: '出去吃' }, { value: '吃泡面' }]).value(this.inputType).onSelect((i, v) => this.inputType = v)
          Select([{ value: '拉完了' }, { value: 'NPC' }, { value: '人上人' }, { value: '頂級' }, { value: '夯' }]).value(this.levels[this.selectedLevelIndex]).onSelect((index) => this.selectedLevelIndex = index)
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)
        Button(this.editingIndex === -1 ? '納入飯單' : '確認修改').width('100%').height(40).onClick(() => this.saveShop())
      }.padding(20).margin({ top: 10 })

      // --- 底部列表區 ---
      Text('江湖飯單').fontSize(16).margin({ top: 10, left: 20 }).width('100%')
      List({ space: 10 }) {
        ForEach(this.shops, (item: Shop, index: number) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.name).fontSize(16).fontWeight(FontWeight.Bold)
                Text(item.type).fontSize(12).fontColor('#999999').margin({ top: 4 })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Row({ space: 15 }) {
                Text(item.level).fontColor('#FFFFFF').fontSize(12).fontWeight(FontWeight.Bold).backgroundColor(this.getLevelColor(item.level)).padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(10)
                Text('改').fontSize(14).fontColor('#007DFF').onClick(() => this.startEdit(index))
                Text('刪').fontSize(14).fontColor('#D32F2F').onClick(() => this.deleteShop(index))
              }
            }.width('100%').padding(15).backgroundColor('#FFFFFF').borderRadius(12)
          }
        })
      }.layoutWeight(1).padding({ left: 20, right: 20, bottom: 20 }).width('100%')
    }.width('100%').height('100%').backgroundColor('#F5F7FA')
  }
}